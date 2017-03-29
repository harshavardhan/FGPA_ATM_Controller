/*
   Original 64 bit -> | User 16-bit | Password 16-bit | 2k 8-bit | 1k 8-bit | 500 8-bit | 100 8-bit |
   (in VHDL before encryption)  8 7 6 5 4 3 2 1	
*/
#define _GNU_SOURCE

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <argtable2.h>
#include <string.h>
#include <libfpgalink.h>

#include <errno.h>
#include <makestuff.h>
#include <libbuffer.h>
#include <liberror.h>
#include <libdump.h>
#include <readline/readline.h>
#include <readline/history.h>

#ifdef WIN32
#include <Windows.h>
#else

#include <sys/time.h>

#endif
#define N 100005

int dataFromCSV[N][4];
int numLines = 0;
bool LOG = false;

/* Adapted from tiny encryption algorithm wikipedia */
void decrypt(uint32_t *v, uint32_t *k) {
    uint32_t v0 = v[0], v1 = v[1], sum = 0xC6EF3720, i;  /* set up */
    uint32_t delta = 0x9e3779b9;                     /* a key schedule constant */
    uint32_t k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3];   /* cache key */
    /* basic cycle start */
    for (i = 0; i < 32; i++) {
        v1 -= ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
        v0 -= ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
        sum -= delta;
    }
    /* end cycle */
    v[0] = v0;
    v[1] = v1;
}

/* Adapted from tiny encryption algorithm wikipedia */
void encrypt(uint32_t *v, uint32_t *k) {
    uint32_t v0 = v[0], v1 = v[1], sum = 0, i;           /* set up */
    uint32_t delta = 0x9e3779b9;                     /* a key schedule constant */
    uint32_t k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3];   /* cache key */
    /* basic cycle start */
    for (i = 0; i < 32; i++) {
        sum += delta;
        v0 += ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
        v1 += ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
    }
    /* end cycle */
    v[0] = v0;
    v[1] = v1;
}

void decrypt64(uint32_t *inpData) {
    uint32_t key[4];
    key[0] = 0x2927c18c;
    key[1] = 0x75f8c48f;
    key[2] = 0x43fd99f7;
    key[3] = 0xff0f7457;
    decrypt(inpData, key);
}

void encrypt64(uint32_t *inpData) {
    uint32_t key[4];
    key[0] = 0x2927c18c;
    key[1] = 0x75f8c48f;
    key[2] = 0x43fd99f7;
    key[3] = 0xff0f7457;
    encrypt(inpData, key);
}

uint16_t myHash(uint16_t befHash) {
    uint16_t ret = 0;
    for (uint16_t i = 0; i <= 15; i++) {
        if ((befHash & (1 << i)) != 0) {
            uint16_t j = ((i + 11) % 16);
            ret += (1 << j);
        }
    }
    return ret;
}

void format(char *line) {
    char *wordPtr;
    wordPtr = strtok(line, ",");
    int cnt = 0;
    while (wordPtr != NULL) {
        sscanf(wordPtr, "%d", &dataFromCSV[numLines][cnt]);
        wordPtr = strtok(NULL, ",");
        cnt++;
    }
}

bool find(uint16_t userID, uint16_t hashedPin, bool *isAdmin, int *bal, int *inLineNum) {
    bool pos = false;
    for (int i = 1; i <= numLines; i++) {
        if (userID == (uint16_t) dataFromCSV[i][0] && hashedPin == (uint16_t) dataFromCSV[i][1]) {
            pos = true;
            if (dataFromCSV[i][2] == 1) *isAdmin = true;
            *bal = dataFromCSV[i][3];
            *inLineNum = i;
            break;
        }
    }
    return pos;
}

bool suffBal(int bal, int *reqAmo, uint8_t num_100, uint8_t num_500, uint8_t num_1000, uint8_t num_2000) {
    bool hasSuffBal = true;
    *reqAmo += 100 * ((int) num_100);
    *reqAmo += 500 * ((int) num_500);
    *reqAmo += 1000 * ((int) num_1000);
    *reqAmo += 2000 * ((int) num_2000);
    if (*reqAmo > bal) hasSuffBal = false;
    return hasSuffBal;
}

static const char *const errMessages[] = {
        NULL,
        NULL,
        "Unparseable hex number",
        "Channel out of range",
        "Conduit out of range",
        "Illegal character",
        "Unterminated string",
        "No memory",
        "Empty string",
        "Odd number of digits",
        "Cannot load file",
        "Cannot save file",
        "Bad arguments"
};

typedef enum {
    FLP_SUCCESS,
    FLP_LIBERR,
    FLP_BAD_HEX,
    FLP_CHAN_RANGE,
    FLP_CONDUIT_RANGE,
    FLP_ILL_CHAR,
    FLP_UNTERM_STRING,
    FLP_NO_MEMORY,
    FLP_EMPTY_STRING,
    FLP_ODD_DIGITS,
    FLP_CANNOT_LOAD,
    FLP_CANNOT_SAVE,
    FLP_ARGS
} ReturnCode;

int main(int argc, char *argv[]) {
    ReturnCode retVal = FLP_SUCCESS;

    struct arg_str *ivpOpt = arg_str0("i", "ivp", "<VID:PID>", "            vendor ID and product ID (e.g 04B4:8613)");
    struct arg_str *vpOpt = arg_str1("v", "vp", "<VID:PID[:DID]>", "       VID, PID and opt. dev ID (e.g 1D50:602B:0001)");
    struct arg_lit *loopOpt = arg_lit0("y", "atm", "                    communicates with the atm module");
    struct arg_lit *verboseOpt = arg_lit0("l", "log", "        gives log on more events");
    struct arg_lit *helpOpt = arg_lit0("h", "help", "                     print this help and exit");
    struct arg_end *endOpt = arg_end(20);

    void *argTable[] = {
            ivpOpt,
            vpOpt,
            loopOpt,
            verboseOpt,
            helpOpt,
            endOpt
    };

    const char *progName = "flcli";
    int numErrors;
    struct FLContext *handle = NULL;
    FLStatus fStatus;
    const char *error = NULL;
    const char *ivp = NULL;
    const char *vp = NULL;
    bool isCommCapable;
    const char *line = NULL;
    uint8 conduit = 0x01;

    if (arg_nullcheck(argTable) != 0) {
        fprintf(stderr, "%s: insufficient memory\n", progName);
        FAIL(1, cleanup);
    }

    numErrors = arg_parse(argc, argv, argTable);

    if (verboseOpt->count > 0) {
        LOG = true;
    }

    if (helpOpt->count > 0) {
        printf("FPGALink Command-Line Interface Copyright (C) 2017 Jarvis \n\n Usage: %s", progName);
        arg_print_syntax(stdout, argTable, "\n");
        printf("\nInteract with an FPGALink device.\n\n");
        arg_print_glossary(stdout, argTable, "  %-10s %s\n");
        FAIL(FLP_SUCCESS, cleanup);
    }

    if (numErrors > 0) {
        arg_print_errors(stdout, endOpt, progName);
        fprintf(stderr, "Try '%s --help' for more information.\n", progName);
        FAIL(FLP_ARGS, cleanup);
    }

    fStatus = flInitialise(0, &error);
    CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);

    vp = vpOpt->sval[0];

    printf("Attempting to open connection to FPGALink device %s...\n", vp);
    fStatus = flOpen(vp, &handle, NULL);
    if (fStatus) {
        if (ivpOpt->count) {
            int count = 60;
            uint8 flag;
            ivp = ivpOpt->sval[0];
            printf("Loading firmware into %s...\n", ivp);
            fStatus = flLoadStandardFirmware(ivp, vp, &error);
            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);

            printf("Awaiting renumeration");
            flSleep(1000);
            do {
                printf(".");
                fflush(stdout);
                fStatus = flIsDeviceAvailable(vp, &flag, &error);
                CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                flSleep(250);
                count--;
            } while (!flag && count);
            printf("\n");
            if (!flag) {
                fprintf(stderr, "FPGALink device did not renumerate properly as %s\n", vp);
                FAIL(FLP_LIBERR, cleanup);
            }

            printf("Attempting to open connection to FPGLink device %s again...\n", vp);
            fStatus = flOpen(vp, &handle, &error);
            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
        } else {
            fprintf(stderr, "Could not open FPGALink device at %s and no initial VID:PID was supplied\n", vp);
            FAIL(FLP_ARGS, cleanup);
        }
    }

    printf(
            "Connected to FPGALink device %s (firmwareID: 0x%04X, firmwareVersion: 0x%08X)\n",
            vp, flGetFirmwareID(handle), flGetFirmwareVersion(handle)
    );

    isCommCapable = flIsCommCapable(handle, conduit);

    // -y reads in from csv and initiates the while loop
    if (loopOpt->count > 0) {
        if (isCommCapable) {
            uint8 isRunning;
            fStatus = flSelectConduit(handle, conduit, &error);
            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
            fStatus = flIsFPGARunning(handle, &isRunning, &error);
            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
            if (isRunning) {

                FILE *fPtr;
                fPtr = fopen("SampleBackEndDatabase.csv", "r+"); // change flag according to need
                if (fPtr == NULL) {
                    printf("Csv doesn't exist \n");
                    return 0;
                }
                size_t lineSize = 100;
                char *lineFromFile = malloc(lineSize * sizeof(char));

                while ((getline(&lineFromFile, &lineSize, fPtr)) != -1) {
                    if (numLines != 0) format(lineFromFile);
                    numLines++;
                }
                numLines--;
                free(lineFromFile);
                fclose(fPtr);

                while (true) {
                    uint32_t length = 1;
                    uint8_t *readFromChannelZero = malloc(sizeof(uint8_t));

                    fStatus = flReadChannel(handle, (uint8_t) 0, length, readFromChannelZero, &error);
                    CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                    if (LOG) printf("Read from channel 0 = %u \n", *readFromChannelZero);

                    if (((*readFromChannelZero) == 1) || ((*readFromChannelZero) == 2)) {
                        uint8_t cnt = 1, valRead = *readFromChannelZero;
                        bool cont = true;
                        while (cnt < 3) {

                            flSleep(1000);
                            fStatus = flReadChannel(handle, 0, length, readFromChannelZero, &error);
                            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                            if (LOG) printf("Read from channel 0 = %u \n", *readFromChannelZero);

                            if (*readFromChannelZero == valRead) cnt++;
                            else {
                                cont = false;
                                break;
                            }
                        }
                        if (cont) {
                            uint32_t inpFromFrontEnd[2];
                            for (int i = 0; i < 2; i++) inpFromFrontEnd[i] = 0;
                            for (uint32_t i = 1; i <= 8; i++) {
                                uint8_t *readFromChannel_i = malloc(sizeof(uint8_t));

                                flSleep(1000);
                                fStatus = flReadChannel(handle, (uint8_t) i, length, readFromChannel_i, &error);
                                CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                if (LOG) printf("Read from channel %u = %u \n", i, *readFromChannel_i);
                                uint32_t temp1 = 8 * (i - 1), temp2 = 8 * (i - 5);
                                if (i <= 4) inpFromFrontEnd[0] += (*readFromChannel_i) * (1 << temp1);
                                else inpFromFrontEnd[1] += (*readFromChannel_i) * (1 << temp2);
                            }
                            decrypt64(inpFromFrontEnd);
                            uint8_t num_100 = 0, num_500 = 0, num_1000 = 0, num_2000 = 0;
                            uint16_t userID = 0, unhashedPin = 0;
                            for (uint8_t i = 1; i <= 32; i++) {
                                if (i <= 8) {
                                    if ((inpFromFrontEnd[0] & (1 << (i - 1))) != 0) num_100 += ((1 << (i - 1)));
                                } else if (i <= 16) {
                                    if ((inpFromFrontEnd[0] & (1 << (i - 1))) != 0) num_500 += ((1 << (i - 9)));
                                } else if (i <= 24) {
                                    if ((inpFromFrontEnd[0] & (1 << (i - 1))) != 0) num_1000 += ((1 << (i - 17)));
                                } else {
                                    if ((inpFromFrontEnd[0] & (1 << (i - 1))) != 0) num_2000 += ((1 << (i - 25)));
                                }
                            }
                            for (uint16_t i = 1; i <= 32; i++) {
                                if (i <= 16) {
                                    if ((inpFromFrontEnd[1] & (1 << (i - 1))) != 0) unhashedPin += ((1 << (i - 1)));
                                } else {
                                    if ((inpFromFrontEnd[1] & (1 << (i - 1))) != 0) userID += ((1 << (i - 17)));
                                }
                            }
//                            printf("unhashedPin %u\n", unhashedPin);
//                            printf("userID %u\n", userID);
                            uint16_t hashedPin = myHash(unhashedPin);
//                            printf("hashedPin %u\n", hashedPin);
//                            printf("num_2000 %u\n", num_2000);
//                            printf("num_1000 %u\n", num_1000);
//                            printf("num_500 %u\n", num_500);
//                            printf("num_100 %u\n", num_100);

                            int bal = -1;
                            bool isAdmin = false;
                            int inLineNum = -1;
                            uint8_t *statusOnChan9 = malloc(sizeof(uint8_t));
                            if (find(userID, hashedPin, &isAdmin, &bal, &inLineNum)) {
                                printf("Valid user found \n");
                                if (!isAdmin) {
                                    int reqAmo = 0;
                                    if (suffBal(bal, &reqAmo, num_100, num_500, num_1000, num_2000)) {
//                                        printf("bal %u\n", bal);
//                                        printf("req %u\n", reqAmo);
                                        if (LOG) printf("Sufficient Balance in account\n");
                                        *statusOnChan9 = 1;
                                        flSleep(1000);
                                        if (LOG) printf("Write to channel %u = %u \n", 9, *statusOnChan9);
                                        fStatus = flWriteChannel(handle, (uint8_t) 9, length, statusOnChan9, &error);
                                        CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                        flSleep(1000);
                                        uint32_t befEncSen[2];
                                        for (int i = 0; i < 2; i++) befEncSen[i] = 0;
                                        for (uint32_t i = 0; i <= 31; i += 8) {
                                            if (i == 0) befEncSen[0] += ((1 << i) * ((uint32_t) num_100));
                                            else if (i == 8) befEncSen[0] += ((1 << i) * ((uint32_t) num_500));
                                            else if (i == 16) befEncSen[0] += ((1 << i) * ((uint32_t) num_1000));
                                            else befEncSen[0] += ((1 << i) * ((uint32_t) num_2000));
                                        }
                                        encrypt64(befEncSen);
                                        for (uint8_t i = 10; i <= 13; i++) {
                                            uint8_t tempSto = 0;
                                            for (uint8_t j = 0; j <= 7; j++) {
                                                uint8_t temp = j + (i - 10) * 8;
                                                if ((befEncSen[0] & (1 << temp)) != 0) {
                                                    tempSto += (1 << j);
                                                }
                                            }
                                            flSleep(1000);
                                            fStatus = flWriteChannel(handle, (uint8_t) i, length, &tempSto, &error);
                                            if (LOG) printf("Write to channel %u = %u \n", i, tempSto);
                                            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                        }

                                        for (uint8_t i = 14; i <= 17; i++) {
                                            uint8_t tempSto = 0;
                                            for (uint8_t j = 0; j <= 7; j++) {
                                                uint8_t temp = j + (i - 14) * 8;
                                                if ((befEncSen[1] & (1 << temp)) != 0) {
                                                    tempSto += (1 << j);
                                                }
                                            }
                                            flSleep(1000);
                                            fStatus = flWriteChannel(handle, (uint8_t) i, length, &tempSto, &error);
                                            if (LOG) printf("Write to channel %u = %u \n", i, tempSto);
                                            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                        }
                                        /* update the balance in the global variable now and update the csv here itself */
                                        if ((*readFromChannelZero) == 1) {
                                            dataFromCSV[inLineNum][3] -= reqAmo;

                                            /* Updating csv file in place */
                                            fPtr = fopen("SampleBackEndDatabase.csv", "w+"); // change flag according to need
                                            fprintf(fPtr, "%s", "\"User ID (decimal)\",\"PIN Hash (decimal)\",\"Admin\",\"Balance (decimal)\"");
                                            fprintf(fPtr, "\n");
                                            for (int i = 1; i <= numLines; i++) {
                                                for (int k = 0; k < 4; k++) {
                                                    fprintf(fPtr, "%d", dataFromCSV[i][k]);
                                                    if (k == 3) {
                                                        if (i != numLines) fprintf(fPtr, "\n");
                                                    } else fprintf(fPtr, ",");
                                                }
                                            }
                                            fclose(fPtr);
                                        }
                                    } else {
//                                        printf("bal %u\n", bal);
//                                        printf("req %u\n", reqAmo);
                                        if (LOG) printf("Insufficient Balance \n");
                                        *statusOnChan9 = 2;
                                        flSleep(1000);
                                        if (LOG) printf("Write to channel %u = %u \n", 9, *statusOnChan9);
                                        fStatus = flWriteChannel(handle, (uint8_t) 9, length, statusOnChan9, &error);
                                        CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                        for (int i = 10; i <= 17; i++) {
                                            uint8_t tempSto = 0;
                                            flSleep(1000);
                                            if (LOG) printf("Write to channel %u = %u \n", i, tempSto);
                                            fStatus = flWriteChannel(handle, (uint8_t) i, length, &tempSto, &error);
                                            CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                        }
                                    }
                                } else {
                                    printf("User has admin privileges \n");
                                    *statusOnChan9 = 3;
                                    flSleep(1000);
                                    if (LOG) printf("Write to channel %u = %u \n", 9, *statusOnChan9);
                                    fStatus = flWriteChannel(handle, (uint8_t) 9, length, statusOnChan9, &error);
                                    CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                    uint32_t befEncSen[2];
                                    for (int i = 0; i < 2; i++) befEncSen[i] = 0;
                                    for (uint32_t i = 0; i <= 31; i += 8) {
                                        if (i == 0) befEncSen[0] += ((1 << i) * ((uint32_t) num_100));
                                        else if (i == 8) befEncSen[0] += ((1 << i) * ((uint32_t) num_500));
                                        else if (i == 16) befEncSen[0] += ((1 << i) * ((uint32_t) num_1000));
                                        else befEncSen[0] += ((1 << i) * ((uint32_t) num_2000));
                                    }
                                    encrypt64(befEncSen);
                                    for (uint8_t i = 10; i <= 13; i++) {
                                        uint8_t tempSto = 0;
                                        for (uint8_t j = 0; j <= 7; j++) {
                                            uint8_t temp = j + (i - 10) * 8;
                                            if ((befEncSen[0] & (1 << temp)) != 0) {
                                                tempSto += (1 << j);
                                            }
                                        }
                                        flSleep(1000);
                                        if (LOG) printf("Write to channel %u = %u \n", i, tempSto);
                                        fStatus = flWriteChannel(handle, (uint8_t) i, length, &tempSto, &error);
                                        CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                    }

                                    for (uint8_t i = 14; i <= 17; i++) {
                                        uint8_t tempSto = 0;
                                        for (uint8_t j = 0; j <= 7; j++) {
                                            uint8_t temp = j + (i - 14) * 8;
                                            if ((befEncSen[1] & (1 << temp)) != 0) {
                                                tempSto += (1 << j);
                                            }
                                        }
                                        flSleep(1000);
                                        if (LOG) printf("Write to channel %u = %u \n", i, tempSto);
                                        fStatus = flWriteChannel(handle, (uint8_t) i, length, &tempSto, &error);
                                        CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                    }
                                }
                            } else {
                                printf("Invalid user \n");
                                *statusOnChan9 = 4;
                                flSleep(1000);
                                if (LOG) printf("Write to channel %u = %u \n", 9, *statusOnChan9);
                                fStatus = flWriteChannel(handle, (uint8_t) 9, length, statusOnChan9, &error);
                                CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                for (int i = 10; i <= 17; i++) {
                                    uint8_t tempSto = 0;
                                    flSleep(1000);
                                    if (LOG) printf("Write to channel %u = %u \n", i, tempSto);
                                    fStatus = flWriteChannel(handle, (uint8_t) i, length, &tempSto, &error);
                                    CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
                                }
                            }
                        }
                    }
                    flSleep(1000);
                }

            } else {
                fprintf(stderr, "The FPGALink device at %s is not ready to talk - did you forget --program?\n", vp);
                FAIL(FLP_ARGS, cleanup);
            }
        } else {
            fprintf(stderr, "Action requested but device at %s does not support CommFPGA\n", vp);
            FAIL(FLP_ARGS, cleanup);
        }
    }

    cleanup:
    free((void *) line);
    flClose(handle);
    if (error) {
        fprintf(stderr, "%s\n", error);
        flFreeError(error);
    }
    return retVal;
}