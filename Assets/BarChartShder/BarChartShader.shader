Shader "Hidden/BarChartShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
#define bars 32.0                 // How many buckets to divide spectrum into
#define barSize 1.0 / bars        // Constant to avoid division in main loop
#define barGap 0.1 * barSize      // 0.1 represents gap on both sides, so a bar is
			// shown to be 80% as wide as the spectrum it samples
#define sampleSize 0.02           // How accurately to sample spectrum, must be a factor of 1.0
			// Setting this too low may crash your browser!

			// Helper for intensityToColour
			float h2rgb(float h)
			{
				if (h < 0.0) h += 1.0;
				if (h < 0.166666) return 0.1 + 4.8 * h;
				if (h < 0.5) return 0.9;
				if (h < 0.666666) return 0.1 + 4.8 * (0.666666 - h);
				return 0.1;
			}

			// Map [0, 1] to rgb using hues from [240, 0] - ie blue to red
			float3 intensityToColour(float i)
			{
				// Algorithm rearranged from http://www.w3.org/TR/css3-color/#hsl-color
				// with s = 0.8, l = 0.5
				float h = 0.666666 - (i * 0.666666);

				return float3(h2rgb(h + 0.333333), h2rgb(h), h2rgb(h - 0.333333));
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 fragColor = tex2D(_MainTex, i.uv);
				// Map input coordinate to [0, 1)
				float2 uv = float2(i.uv.x, 1 - i.uv.y);

				// Get the starting x for this bar by rounding down
				float barStart = floor(uv.x * bars) / bars;

				// Discard pixels in the 'gap' between bars
				if (uv.x - barStart < barGap || uv.x > barStart + barSize - barGap)
				{
					fragColor = (float4)1.0;
				}
				else
				{
					// Sample spectrum in bar area, keep cumulative total
					float intensity = 0.0;
					for (float s = 0.0; s < barSize; s += barSize * sampleSize)
					{
						// Shader toy shows loudness at a given frequency at (f, 0) with the same value in all channels
						intensity += tex2D(_MainTex, float2(barStart + s, 0.0)).r;
					}
					intensity *= sampleSize; // Divide total by number of samples taken (which is 1 / sampleSize)
					intensity = clamp(intensity, 0.005, 1.0); // Show silent spectrum to be just poking out of the bottom

															  // Only want to keep this pixel if it is lower (screenwise) than this bar is loud
					float i = float(intensity > uv.y); // Casting a comparison to float sets i to 0.0 or 1.0

													   //fragColor = vec4(intensityToColour(uv.x), 1.0);       // Demo of HSL function
													   //fragColor = vec4(i);                                  // Black and white output
					fragColor = float4(intensityToColour(intensity) * i, i);  // Final output
				}
				// Note that i2c output is multiplied by i even though i is sent in the alpha channel
				// This is because alpha is not 'pre-multiplied' for fragment shaders, you need to do it yourself
				return fragColor;
			}
			ENDCG
		}
	}
}