Shader "FX/Mirror Reflection2" {
	Properties{
		_Color("Diffuse Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex("Diffuse (RGB) Transparent (A)", 2D) = "white" {}
		_IllumFactor("Illumin Factor", Range(1,2)) = 1
	}

	Subshader
	{
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _IllumFactor;
			float4x4 _texViewProj;
			sampler2D _ReflectTex;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uvReflect : TEXCOORD1;
			};
			inline float4 ReflectUV(float4 worldPos)
			{
				float4 viewPos = mul(_texViewProj, float4(worldPos.xyz, 1));
				viewPos = viewPos / viewPos.w;
				viewPos.xy = (viewPos.xy + fixed2(1.0f, 1.0f)) / 2.0f;//[-1,1]到[0,1]映射
				return viewPos;
			}
			v2f vert(appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = 0;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uvReflect = ReflectUV(worldPos);
				return o;
			}
			inline fixed3 GetReflectColor(fixed2 uvReflect)
			{
				fixed4 lightColor = tex2D(_ReflectTex, uvReflect).rgba;
				return lightColor.rgb;
			}
			float4 frag(v2f i) : COLOR
			{

				float4 tex = tex2D(_MainTex, i.uv.xy);
				fixed3 lightFaceCol = GetReflectColor(i.uvReflect.xy);
				tex.rgb *= _Color * _IllumFactor;
				tex.rgb *= lightFaceCol;
				return tex;
			}
			
			
			ENDCG
		}
	}

}
