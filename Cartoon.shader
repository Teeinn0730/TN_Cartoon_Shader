Shader "Unlit/Cartoon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightMap ("LightMap", 2D) = "white" {}
        [MaterialToggle]_UseFaceMap("UseFaceMap",Float) = 0
        _FaceMap ("FaceMap", 2D) = "white" {}
        _FaceShadowColor ("FaceShadowColor",Color) = (0,0,0,0)
        _RampColor ("_RampColor", 2D) = "white" {}
        _RampColorCount ("RampColorCount" , Float) = 1
        _OutLine("OutLine",Range(0,100))=0.01
        _OColor ("OColor",Color) = (0,0,0,0)
        _LMOColor ("LMOColor",Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass{
            Blend SrcAlpha OneMinusDstAlpha
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 tangent : TEXCOORD1;
            };

            sampler2D _MainTex , _LightMap;
            float4 _MainTex_ST,_MainTex_TexelSize , _LMOColor , _OColor;
            float _OutLine ;

  

            v2f vert (appdata v)
            {
                v2f o;
                o.tangent = 0;
				half3 clipnormal = mul((half3x3)UNITY_MATRIX_MVP,v.tangent.xyz); //不用UnityObjectToClipPos的原因是官方經過簡化，導致這組參數的結果有誤差，繪使角色不在中心時，描邊會位移
				o.vertex = UnityObjectToClipPos(v.vertex);
				half2 offset = normalize(clipnormal.xy) / _ScreenParams.xy * _OutLine *o.vertex.w * v.color.r;
				o.vertex.xy += offset;
                o.vertex.z *=0.995;
                v.normal = normalize(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 LightMap = tex2D(_LightMap,i.uv);
                col.rgb = lerp(col.rgb*_LMOColor.rgb,col.rgb*_OColor.rgb,LightMap.a);
                col.rgb *= _LightColor0.rgb;
                return fixed4(col.rgb,1);
            }
            ENDCG

        }
        Pass
        {
            Tags{
            "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusDstAlpha
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            float InverseLerp (float a , float b , float c ) {
				return saturate((c-a)/(b-a));
			}
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal :TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 projPos : TEXCOORD3;
            };

            sampler2D _MainTex , _LightMap , _RampColor ,_FaceMap ,_CameraDepthTexture;
            float4 _MainTex_ST , _FaceShadowColor , LightDirEulerRotate ;
            half _UseFaceMap , _RampColorCount ;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = (UnityObjectToWorldNormal(v.normal));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.projPos = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f o) : SV_Target
            {
                float attenuation = 1;
                float rim = 0;
                #if defined(SHADOWS_SCREEN)
				    half2 depthUV = o.projPos.xy/o.projPos.w;
//// Full-Shadow:
                    attenuation = tex2D(_ShadowMapTexture, depthUV); 
                    //attenuation = saturate(attenuation+0.5);
//// DepthTex: //硬邊緣高光需要有深度圖來做使用，一般來說只要開啟陰影投射，就必須使用到深度圖，所以不用白不用就寫在一起了。
                    half rimSide = sin(radians(LightDirEulerRotate.y)); //根據光線的方向去做深度圖UV的偏移。
                    const float limitoffset = 0.01/o.pos.w; //值如果太小，鏡頭拉遠很容易會被直接忽略掉，造成clip的現象。
                    const float2 depthoffset = float2(rimSide*limitoffset,limitoffset);
				    half2 depthUVOffset = depthUV + depthoffset;
				    half depth = tex2D(_CameraDepthTexture, depthUVOffset).r;
				    half depthOriginal = tex2D(_CameraDepthTexture, depthUV).r;
                    depth = Linear01Depth(depth);
                    depthOriginal = Linear01Depth(depthOriginal);
				    rim = depth-depthOriginal;
                    rim = step(0.0001/o.pos.w,rim); //除以o.pos.w可以出現更多高量的細節。
                    rim *= _LightColor0.a;
                #endif
///// Struct Light:
                float3 LightDir = _WorldSpaceLightPos0.xyz;
                float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz-o.worldPos.xyz);
                float LDotN = (dot(LightDir,o.normal))*0.5+0.5;
                float LDotV = 1-dot(normalize(_WorldSpaceCameraPos.xyz),LightDir);
                //float VdotN = 1-saturate(normalize(dot(ViewDir.xyz,o.normal)));
                float VdotN = 1-saturate(dot(ViewDir.xyz,o.normal));
                VdotN = InverseLerp(0.5,1,VdotN);
                //return fixed4(VdotN.xxx,1);
///// Struct Texture:
                fixed4 LightMap = tex2D(_LightMap,o.uv);
                fixed4 RampColor = tex2D(_RampColor,float2(saturate(LDotN*attenuation),LightMap.a+(1/(_RampColorCount*2))));//使用黑白灰階圖讀取要使用的顏色條，但是因為各種顏色值都為極端值，所以必須讓這些顏色條的UV往上0.5格。根據你有幾條顏色就除以2倍的顏色條數量。
                fixed4 col = tex2D(_MainTex, o.uv );
                col.rgb *= RampColor.rgb;
                col.rgb *= _LightColor0.rgb;
                if(_UseFaceMap){
                    fixed4 FaceMap = tex2D(_FaceMap,o.uv);  
                    float3 Front = UnityObjectToWorldDir(float3(0,0,1));
                    float3 Up = UnityObjectToWorldDir(float3(0,1,0));
                    float3 Right = cross(Up,Front);

                    float UpRight = dot(LightDir.rgb,Up);
                    float FrontRight = dot(LightDir.rgb,Right);

                    if(FrontRight == 0 && UpRight > 0)
                        FaceMap = 1;
                    if(FrontRight < 0)
                        FaceMap = tex2D(_FaceMap,float2(-o.uv.x,o.uv.y));

                    float fixdegress = abs(cos(radians(LightDirEulerRotate.x)));//因應平行光的X軸會影響貼圖的閾值，所以貼圖顏色跟著Clamp。
                    float FaceShadow = smoothstep(FaceMap.r*fixdegress,(FaceMap.r+0.01)*fixdegress,UpRight);
                    float4 MainTex = tex2D(_MainTex,o.uv);
                    MainTex.rgb = lerp(MainTex.rgb*RampColor.rgb,MainTex.rgb,FaceShadow*attenuation);
                    MainTex.rgb*= _LightColor0.rgb;
                    return fixed4(MainTex.rgb+LDotV*VdotN*rim,1);
                }
///// High Light:
                float3 reflactionDir = reflect(-LightDir,o.normal);
                reflactionDir = reflactionDir*0.5+0.5;
                float VdotRE = DotClamped(ViewDir,reflactionDir);
                float Specular = DotClamped(normalize(ViewDir),normalize(reflactionDir));
                Specular = pow(Specular,100);
                Specular *= LightMap.z*20;
                half3 MetalLight = LightMap.z*(VdotRE>0.85)*3;
                col.rgb += MetalLight + Specular + LDotV*VdotN*rim;
                return fixed4(col.rgb,1);
            }
            ENDCG
        }
		Pass{
			Name"ShadowCaster陰影投射"
			Tags{
				"LightMode" = "ShadowCaster"
			}
			//Offset 1,1
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
            //#pragma multi_compile _ SHADOWS_SCREEN
			//#pragma multi_compile _ VERTEXLIGHT_ON
			//#pragma multi_compile_shadowcaster
			struct VertexInput {
				half4 vertex : POSITION;
                half3 normal : NORMAL;
			};
			//struct VertexOutput{
			//	V2F_SHADOW_CASTER;
			//};
			//VertexOutput vert(VertexInput v) {
			//	VertexOutput o;
			//	o.pos = UnityObjectToClipPos(v.vertex);
			//	TRANSFER_SHADOW_CASTER(o)
			//	return o;
			//}
            half4 vert(VertexInput v):SV_POSITION{
                float4 position = UnityClipSpaceShadowCasterPos(v.vertex.xyz,v.normal);
                position = UnityApplyLinearShadowBias(position);
                //position.z += unity_LightShadowBias.x/v.vertex.w;
                return position;
            }
			half4 frag() :SV_Target{
				return 0;
			}
			ENDCG
		}
    }
}
