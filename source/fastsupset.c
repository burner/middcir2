#include "stdio.h"
#include "stdint.h"
#include "stddef.h"
#include "limits.h"
#include "mmintrin.h" 
#include "xmmintrin.h"
#include "emmintrin.h"
#include "pmmintrin.h"
#include "tmmintrin.h"
#include "smmintrin.h"
#include "nmmintrin.h"
#include "ammintrin.h"
#include "wmmintrin.h"
#include "immintrin.h"

void printBits(size_t const size, void const * const ptr) {
    unsigned char *b = (unsigned char*) ptr;
    unsigned char byte;
    int i, j;

    for (i=size-1;i>=0;i--)
    {
        for (j=7;j>=0;j--)
        {
            byte = (b[i] >> j) & 1;
            printf("%u", byte);
        }
    }
    puts("");
}

void print256_num(__m256 var) {
    uint32_t* v32val = (uint32_t*) &var;
	for(int i = 0; i < 8; ++i) {
		printBits(sizeof(uint32_t), v32val + i);
	}
	printf("\n");
}

uint32_t fastSubsetFind(uint32_t* restrict ptr, size_t len, uint32_t supSet) {
	__m256 ss = _mm256_set_epi32(
			supSet, supSet, 
			supSet, supSet,
			supSet, supSet, 
			supSet, supSet
		);
	//print256_num(ss);

	__m256 mask = _mm256_set_epi32(
			0b10000000, 0b01000000,
			0b00100000, 0b00010000, 
			0b00001000, 0b00000100, 
			0b00000010, 0b00000001
		);
	//print256_num(mask);

	size_t i = 0;

	uint32_t tmp[8] = { 0,0,0,0,0,0,0,0 };
	uint32_t tmpMerge = 0;
	int32_t rslt = 0;
	size_t lenMod8 = len - (len % 8UL);
	for(; i < lenMod8; i += 8UL) {
		// load 16 ushorts
		__m256 tt = _mm256_loadu_ps((float*)(ptr + i));
		//print256_num(tt);

		// logical and these 16 ushort to supSet
		__m256 afterAnd = _mm256_and_ps(tt, ss);

		__m256 cmp = _mm256_cmp_ps(afterAnd, tt, 0);
		__m256 selMask = _mm256_and_ps(cmp, mask);
		//print256_num(selMask);

		_mm256_storeu_ps((float*)tmp, selMask);
		tmpMerge = tmp[0] | tmp[1] | tmp[2] | tmp[3] | tmp[4] | tmp[5] | tmp[6] | tmp[7];

		rslt = __builtin_ffs((int32_t)tmpMerge);
		//printf("%d\n", rslt);
		if(rslt != 0) {
			return *(ptr + (rslt - 1));
		}
	}

	//#pragma clang loop unroll_count(2) 
	for(; i < len; ++i) {
		if((*(ptr + i) & supSet) == supSet) {
			return *(ptr + i);
		}
	}
	return UINT_MAX;
}

