#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
uint8_t sobel_3x3(uint8_t p[3][3], int threshold)
{
    int gx;
    int gy;
    int magnitude;
    // Sobel X
    gx =
        -p[0][0] + p[0][2]
        -2 * p[1][0] + 2 * p[1][2]
        -p[2][0] + p[2][2];
    // Sobel Y
    gy =
        -p[0][0] - 2 * p[0][1] - p[0][2]
        +p[2][0] + 2 * p[2][1] + p[2][2];
    magnitude = abs(gx) + abs(gy);
    if (magnitude >= threshold)
        return 1;
    else
        return 0;
}
int main(void)
{
    FILE *fp;
    FILE *result_fp;
    uint8_t pixel[3][3];
    uint8_t edge;
    int data;
    int i;
    int j;
    fp = fopen("random_0_255.txt", "r");
    if (fp == NULL) {
        printf("Input file open error\n");
        return 1;
    }
    result_fp = fopen("sobel_result.txt", "w");
    if (result_fp == NULL) {
        printf("Output file open error\n");
        fclose(fp);
        return 1;
    }
    while (1) {
        for (i = 0; i < 3; i++) {
            for (j = 0; j < 3; j++) {
                if (fscanf(fp, "%d", &data) != 1) {
                    fclose(fp);
                    fclose(result_fp);
                    printf("Sobel processing complete\n");
                    return 0;
                }
                pixel[i][j] = (uint8_t)data;
            }
        }
        edge = sobel_3x3(pixel, 95);
        fprintf(result_fp, "%u\n", edge);
    }
    return 0;
}
