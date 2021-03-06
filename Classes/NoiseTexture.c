/*
 *  NoiseTexture.c
 *  Havoc Video
 *
 *  Created by Richard Insley on 9/9/10.
 *  Copyright 2010 WildWestWare. All rights reserved.
 *
 */

#include "NoiseTexture.h"

#define MAXB 0x100
#define N 0x1000
#define NP 12   // 2^N
#define NM 0xfff

#define s_curve(t) ( t * t * (3. - 2. * t) )
#define lerp(t, a, b) ( a + t * (b - a) )
#define setup(i, b0, b1, r0, r1)\
t = vec[i] + N;\
b0 = ((int)t) & BM;\
b1 = (b0+1) & BM;\
r0 = t - (int)t;\
r1 = r0 - 1.;
#define at2(rx, ry) ( rx * q[0] + ry * q[1] )
#define at3(rx, ry, rz) ( rx * q[0] + ry * q[1] + rz * q[2] )

static int p[MAXB + MAXB + 2];
static float g3[MAXB + MAXB + 2][3];
static float g2[MAXB + MAXB + 2][2];
static float g1[MAXB + MAXB + 2];

static int start = 1;
static int B;
static int BM;

void SetNoiseFrequency(int frequency)
{
	start = 1;
	B = frequency;
	BM = B-1;
}

void normalize2(float v[2])
{
	float s;
	
	s = sqrt(v[0] * v[0] + v[1] * v[1]);
	v[0] = v[0] / s;
	v[1] = v[1] / s;
}

void normalize3(float v[3])
{
	float s;
	
	s = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
	v[0] = v[0] / s;
	v[1] = v[1] / s;
	v[2] = v[2] / s;
}

void initNoise()
{
	int i, j, k;
	
	// we don't want to reset the noise seed every time
	//srand(30757);
	for (i = 0; i < B; i++)
	{
		p[i] = i;
		g1[i] = (float)((rand() % (B + B)) - B) / B;
		
		for (j = 0; j < 2; j++)
			g2[i][j] = (float)((rand() % (B + B)) - B) / B;
		normalize2(g2[i]);
		
		for (j = 0; j < 3; j++)
			g3[i][j] = (float)((rand() % (B + B)) - B) / B;
		normalize3(g3[i]);
	}
	
	while (--i)
	{
		k = p[i];
		p[i] = p[j = rand() % B];
		p[j] = k;
	}
	
	for (i = 0; i < B + 2; i++)
	{
		p[B + i] = p[i];
		g1[B + i] = g1[i];
		for (j = 0; j < 2; j++)
			g2[B + i][j] = g2[i][j];
		for (j = 0; j < 3; j++)
			g3[B + i][j] = g3[i][j];
	}
}


float noise3(float vec[3])
{
	int bx0, bx1, by0, by1, bz0, bz1, b00, b10, b01, b11;
	float rx0, rx1, ry0, ry1, rz0, rz1, *q, sy, sz, a, b, c, d, t, u, v;
	int i, j;
	
	if (start)
	{
		start = 0;
		initNoise();
	}
	
	setup(0, bx0, bx1, rx0, rx1);
	setup(1, by0, by1, ry0, ry1);
	setup(2, bz0, bz1, rz0, rz1);
	
	i = p[bx0];
	j = p[bx1];
	
	b00 = p[i + by0];
	b10 = p[j + by0];
	b01 = p[i + by1];
	b11 = p[j + by1];
	
	t  = s_curve(rx0);
	sy = s_curve(ry0);
	sz = s_curve(rz0);
	
	q = g3[b00 + bz0]; u = at3(rx0, ry0, rz0);
	q = g3[b10 + bz0]; v = at3(rx1, ry0, rz0);
	a = lerp(t, u, v);
	
	q = g3[b01 + bz0]; u = at3(rx0, ry1, rz0);
	q = g3[b11 + bz0]; v = at3(rx1, ry1, rz0);
	b = lerp(t, u, v);
	
	c = lerp(sy, a, b);
	
	q = g3[b00 + bz1]; u = at3(rx0, ry0, rz1);
	q = g3[b10 + bz1]; v = at3(rx1, ry0, rz1);
	a = lerp(t, u, v);
	
	q = g3[b01 + bz1]; u = at3(rx0, ry1, rz1);
	q = g3[b11 + bz1]; v = at3(rx1, ry1, rz1);
	b = lerp(t, u, v);
	
	d = lerp(sy, a, b);
	
	return lerp(sz, c, d);
}

void make3DNoiseTexture(int width, int height, int layers, GLubyte* Noise3DTexPtr)
{
	int f, i, j, k, inc;
	int startFrequency = 4;
	int numOctaves = 4;
	float ni[3];
	float inci, incj, inck;
	int frequency = startFrequency;
	GLubyte* ptr;
	float amp = 0.5;
	
	for (f = 0, inc = 0; f < numOctaves; ++f, frequency *= 2, ++inc, amp *= 0.5)
	{
		SetNoiseFrequency(frequency);
		ptr = Noise3DTexPtr;
		ni[0] = ni[1] = ni[2] = 0;
		
		inci = 1.0 / (layers / frequency);
		for (i = 0; i < layers; ++i, ni[0] += inci)
		{
			incj = 1.0 / (height / frequency);
			for (j = 0; j < height; ++j, ni[1] += incj)
			{
				inck = 1.0 / (width / frequency);
				for (k = 0; k < width; ++k, ni[2] += inck, ptr += 4)
					*(ptr + inc) = (GLubyte) (((noise3(ni) + 1.0) * amp) * 128.0);
			}
		}
	}
	
	return;
}