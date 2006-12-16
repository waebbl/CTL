///////////////////////////////////////////////////////////////////////////////
// 
// Copyright (c) 2006 Academy of Motion Picture Arts and Sciences
// ("A.M.P.A.S."). Portions contributed by others as indicated.
// All rights reserved.
// 
// A world-wide, royalty-free, non-exclusive right to distribute, copy,
// modify, create derivatives, and use, in source and binary forms, is
// hereby granted, subject to acceptance of this license. Performance of
// any of the aforementioned acts indicates acceptance to be bound by the
// following terms and conditions:
// 
//   * Redistributions of source code, in whole or in part, must
//     retain the above copyright notice, this list of conditions and
//     the Disclaimer of Warranty.
// 
//   * Redistributions in binary form must retain the above copyright
//     notice, this list of conditions and the Disclaimer of Warranty
//     in the documentation and/or other materials provided with the
//     distribution.
// 
//   * Nothing in this license shall be deemed to grant any rights to
//     trademarks, copyrights, patents, trade secrets or any other
//     intellectual property of A.M.P.A.S. or any contributors, except
//     as expressly stated herein.  Neither the name of. A.M.P.A.S. nor
//     any other contributors to this software may be used to endorse or
//     promote products derivative or, or based on this software without
//     express prior written permission of A.M.P.A.S. or contributor, as
//     appropriate.
// 
//   * This license shall be construed pursuant to the laws of the State
//     of California, and any disputes related thereto shall be subject
//     to the jurisdiction of the courts therein.
// 
// Disclaimer of Warranty: THIS SOFTWARE IS PROVIDED BY A.M.P.A.S. AND
// CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
// BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT ARE DISCLAIMED. IN NO
// EVENT SHALL A.M.P.A.S., OR ANY CONTRIBUTORS OR DISTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
// RESITUTIONARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
///////////////////////////////////////////////////////////////////////////////

//
// A transform that converts approximately scene-linear
// RGB values into density values for storing in DPX files.
//

const Chromaticities rec709 =
{
    {0.6400, 0.3300},
    {0.3000, 0.6000},
    {0.1500, 0.0600},
    {0.3172, 0.3290}
};

void
transform_EXR_DPX
    (output varying half dpxR,
     output varying half dpxG,
     output varying half dpxB,
     input varying half R,
     input varying half G,
     input varying half B,
     input uniform Chromaticities chromaticities,
     input uniform float maxAimDensity[3] = {1.890, 2.046, 2.046},
     							// ARRI "carlos" aims
     input uniform float negGamma[3] = {0.55, 0.60, 0.60})
     							// gamma of negative
{
    //
    // Convert input primaries and white point to Rec. 709
    //

    float toRec709[4][4] = mult_f44_f44 (RGBtoXYZ (chromaticities, 1.0), 
				         XYZtoRGB (rec709, 1.0));

    float linear[3] = {R, G, B};
    linear = mult_f3_f44 (linear, toRec709);

    //
    // Clamp linear values to avoid producing NaNs and
    // infinities in the conversion to density below
    //

    if (linear[0] < HALF_MIN)
	linear[0] = HALF_MIN;

    if (linear[1] < HALF_MIN)
	linear[1] = HALF_MIN;

    if (linear[2] < HALF_MIN)
	linear[2] = HALF_MIN;

    //
    // Convert linear Rec. 709 values to densities
    //

    float density[3] =
    {
	negGamma[0] * log10_h (linear[0] / 0.18),
	negGamma[1] * log10_h (linear[1] / 0.18),
	negGamma[2] * log10_h (linear[2] / 0.18)
    };

    //
    // Convert density to DPX code values
    //

    dpxR = density[0] * (1023.0 / maxAimDensity[0]) + 445.0;
    dpxG = density[1] * (1023.0 / maxAimDensity[1]) + 445.0;
    dpxB = density[2] * (1023.0 / maxAimDensity[2]) + 445.0;
}