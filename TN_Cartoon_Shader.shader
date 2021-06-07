Shader "TN/Cartoon_Shader"
{
	Properties
	{
		[Header(ShadowProp     ShadowProp     ShadowProp )][Space][Space]
		_LdotN_Max("SmoothShadow",Range(0,1)) = 0.1
		_LdotN_Val("ShadowProportion",Range(0,1)) = 0.5
		[Header(MainTexProp     MainTexProp     MainTexProp)][Space][Space]
		_MainTex("MainTex", 2D) = "white" {}
		[HDR] _MainColor ("MainTexColor",Color) = (1,1,1,1)
		[HDR] _ShadowColor("ShadowColor",Color) = (0.8,0.8,0.8,1)
		[HDR] _ShadowColor2("ShadowColor2",Color) = (0.8,0.8,0.8,1)
		[MaterialToggle] _useShadowMask ("useShadowMask",Float) = 0
		[MaterialToggle] _useMetalMask ("useMetalMask",Float) = 0
		[MaterialToggle] _useEmissionlMask ("useEmissionMask",Float) = 0
		_Shadow_Metal_Emi_Mask("Shadow Metal Emi Mask",2D) = "white"{}
		_Metal_Intensity("Metal_Intensity",Range(0,1)) = 1
		_Emission_Intensity("Emi_Intensity",Range(0,1)) = 1
		/*
		_HSVRangeMin ("HSV Affect Range Min", Range(0, 1)) = 0
		_HSVRangeMax ("HSV Affect Range Max", Range(0, 1)) = 1
		_HSVAAdjust ("HSVA Adjust", Vector) = (0, 0, 0, 0)
		*/
		[Header(Light     Light     Light)][Space][Space]
		_Light("Light",Color) = (0,0,0,0)
		_Light2("Light2",Color) = (0,0,0,0)
		_LightWrapColor("LightWrapColor",Color) = (0,0,0,0)
		_Fresnel_Intensity("Fresnel_Intensity",Float) = 0
		_Fresnel_pow("Fresnel_pow",Range(-1,1)) = 0
		_Specular_pow("Specular",Range(0,1))=0
		[Header(OutLineProp     OutLineProp     OutLineProp)][Space][Space]
		_OutLine_Width("OutLineScale",Range(0,10)) = 0
		_OutLine_Color("OutLineColor",Color) = (0,0,0,0)
		_OutLine_Color2("OutLineColor2",Color) = (0,0,0,0)
		_OutLine_CutOff("OutLineCutStep",Range(-0.1,1)) = 0.5
		[Header(ColorChangeProp     ColorChangeProp     ColorChangeProp)][Space][Space]
		[Toggle]_ColorChange("ColorChangeToggle",Float) = 0
		_SkinMask("SkinMask",2D) = "white"{}
		_SkinColorChange("SkinColorChange",Color) = (1,1,1,1)
		[Header(AlphaProp     AlphaProp     AlphaProp)][Space][Space]
		_Alpha("Alpha",Range(0,1)) = 1
	}

	SubShader{
		Tags{
			"Queue" = "Geometry"
			"RenderType"="Transparent"
		}
		Pass{
			Name"OutLine描邊"
			Tags{
			}
			Cull Front //有Pass在前面的話則不渲染
			CGPROGRAM
///////pragma參數設定
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest //在執行片元計算時，縮減浮點位元精度，加快計算速度 //ARB_precision_hint_nicest 則反之
			#pragma target 3.0
			#include "UnityCG.cginc"
			//#pragma multi_compile_shadowcaster 用途是使shader支援關於shadowcaster的一些巨集定義，以便支援point light與其他光源的不同處理
///////參數材質建構:
			sampler2D _MainTex; float4 _MainTex_ST;
			sampler2D _SkinMask; float4 _SkinMask_ST;
			sampler2D _ShadowMap; sampler2D _ShadowMap2; sampler2D _Shadow_Metal_Emi_Mask;
			float _OutLine_Width ; float _useShadowMask;
			float4 _OutLine_Color; float4 _OutLine_Color2;
			float _ColorChange;
			float4 _SkinColorChange;
			float _OutLine_CutOff; 
///////模型資訊建構:
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float3 color : COLOR;
				float2 texcoord0 : TEXCOORD0;
				//float4 uv1 : TEXCOORD1;
				};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float3 normal : NORMAL;
				float4 posWorld : TEXCOORD1;
				};
			VertexOutput vert(VertexInput i) {
				VertexOutput o = (VertexOutput) 0;
				o.uv0 = i.texcoord0;
				//i.uv1 = i.uv1*2 -1 ;
				//i.uv1.z = i.normal.y;
				float3 offset = UnityObjectToClipPos(i.tangent).xyz; 
				o.pos = UnityObjectToClipPos(i.vertex);
				o.pos.xy += offset / _ScreenParams.xy *_OutLine_Width * o.pos.w * i.color.r ;
				o.posWorld = mul(unity_ObjectToWorld , i.vertex);
				return o;
				}
////// 建構RGB2HSV函式:
			/*float3 rgb2hsv(float3 c) {
              float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
              float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
              float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

              float d = q.x - min(q.w, q.y);
              float e = 1.0e-10;
              return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }
////// 建構HSV2RGB函式:
            float3 hsv2rgb(float3 c) {
              c = float3(c.x, clamp(c.yz, 0.0, 1.0));
              float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
              float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
              return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }*/
			float4 frag(VertexOutput o) : SV_Target{
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float VdotN = saturate(dot(-ViewDir, o.normal));
				if (VdotN > _OutLine_CutOff) { 
					discard; //不繪製的意思;
					}
				float4 OutLineColor = tex2Dlod(_MainTex , float4(TRANSFORM_TEX(o.uv0,_MainTex),0,5));
				float3 OutLineColor2 = OutLineColor.rgb * _OutLine_Color;
				if(_useShadowMask){
					float ShadowMask = tex2D(_Shadow_Metal_Emi_Mask,o.uv0).r;
					OutLineColor2 = lerp( OutLineColor.rgb *  _OutLine_Color2.rgb , OutLineColor.rgb * _OutLine_Color , ShadowMask);
				}
				
				if (_ColorChange == 0) { // 當換膚色功能關閉，執行:
					return float4(OutLineColor2, 1);
					}
				else { // 否則執行 :
					float SkinMask = tex2D(_SkinMask, TRANSFORM_TEX(o.uv0, _SkinMask)).r;
					float3 SkinChange_OutLineColor = OutLineColor * SkinMask * _SkinColorChange.rgb ;
					float3 SkinChange_OutLineColor2 = lerp(OutLineColor2 , SkinChange_OutLineColor, SkinMask);
					return float4(SkinChange_OutLineColor2, 1);
					}
				}
			ENDCG
		}
		Pass{
			Name "ForwardBase_forEmission基底色(混合自發光)"
			Tags{
				"LightMode" = "ForwardBase"
			}
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			CGPROGRAM
///////pragma參數設定:
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase_fullshadows
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
///////參數材質建構:
			sampler2D _MainTex; float4 _MainTex_ST;
			sampler2D _SkinMask; float4 _SkinMask_ST;
			sampler2D _ShadowMap; sampler2D _ShadowMap2;
			sampler2D _Shadow_Metal_Emi_Mask; 
			float _LdotN_Max , _LdotN_Val , OutLine_Width , OutLine_CutOff , _ColorChange , _Alpha , _useShadowMask , _Fresnel_pow , _Fresnel_Intensity , _Specular_pow , _useMetalMask , _useEmissionlMask , _Emission_Intensity , _Metal_Intensity ;
			float4 _MainColor , _ShadowColor , _ShadowColor2 , _LightWrapColor , OutLine_Color , _SkinColorChange , _Light , _Light2; 
///////模型資訊建構:
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float3 color : COLOR;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float2 uv0 : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				LIGHTING_COORDS(3,4)
				float4 uv1 : TEXCOORD5;
				float3 color : COLOR;
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.uv0 = v.texcoord0;
				o.uv1 = v.uv1;
				o.color = v.color;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
////// Frag:
			float4 frag ( VertexOutput o, float facing : VFACE) : SV_Target {
				float3 LightColor = _LightColor0.rgb;
				float faceSign = (facing >= 0 ? 1 : -1);
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 NormalDir = normalize(o.normalDir)*faceSign;
				float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
				float attenuation = LIGHT_ATTENUATION(o);
////// Light Dot Normal:
				float4 MainTex = tex2D(_MainTex, TRANSFORM_TEX(o.uv0, _MainTex));
				float4 SkinMask = tex2D(_SkinMask, TRANSFORM_TEX(o.uv0, _SkinMask));
				float LdotN = saturate(dot(LightDir, NormalDir));
				float LdotN_Attenuation = saturate(LdotN * attenuation); 
				float LdotN_Att_SmoothStep = smoothstep(LdotN_Attenuation, (LdotN_Attenuation + _LdotN_Max), _LdotN_Val);
				float LdotN_Att_SmoothStep_smooth = smoothstep(LdotN_Attenuation, (LdotN_Attenuation + _LdotN_Max + 0.25), _LdotN_Val+0.1);
				float3 ViewReflect = reflect(-ViewDir,NormalDir);
				float LdotVR = saturate(dot(LightDir, ViewReflect))*0.7+0.3;
////// Shadow Color:
				float3 ShadowColor = 0;
				float4 Shadow_Metal_Emi_Mask = tex2D(_Shadow_Metal_Emi_Mask , o.uv0);
				if(_useShadowMask){
					ShadowColor = lerp( _ShadowColor.rgb , _ShadowColor2.rgb , (1-Shadow_Metal_Emi_Mask.r)) * MainTex.rgb;
				}
				else{
					ShadowColor = _ShadowColor.rgb * MainTex ;
				}
////// Emission:
				float3 EmissionColor = 0;
				if(_useEmissionlMask){
					EmissionColor = Shadow_Metal_Emi_Mask.b * MainTex.rgb * saturate(sin(_Time.g)) * _Emission_Intensity ;
				}
////// Reflect Light:
				float Fresnel = saturate(pow(saturate(dot( -ViewDir , NormalDir )),_Fresnel_pow)*_Fresnel_Intensity);
				float VdotL = saturate(dot( LightDir , -ViewDir ));
				float reflectLight = Fresnel*VdotL;
////// Metal Light
				float3 SpecularLight = 0;
				if(_useMetalMask){
					float3 halfLight = normalize( LightDir + ViewDir );
					SpecularLight = Shadow_Metal_Emi_Mask.g * _LightColor0.rgb * pow(saturate(dot(halfLight,o.normalDir)),_Specular_pow *100)*_Metal_Intensity;
				}
////// Final Color:
				float3 FinalColor = MainTex*_MainColor ;
				float3 Overlay =  (LdotN_Att_SmoothStep_smooth*(1-LdotN_Att_SmoothStep_smooth)) * FinalColor;
				Overlay = lerp( _Light2.rgb * Overlay , _Light.rgb * Overlay , Shadow_Metal_Emi_Mask.r) * _LightColor0.rgb;
				FinalColor = lerp( FinalColor , ShadowColor, float3(LdotN_Att_SmoothStep.xxx));
				FinalColor = FinalColor + Overlay ;
				float3 LightWrap = reflectLight * _LightWrapColor * MainTex;
				float3 FinalColor2_Blend_Screen = saturate(1-(1- FinalColor)*(1- LightWrap));
				float3 FinalColor3 = (1 - attenuation)*FinalColor2_Blend_Screen*LightColor;
				float3 FinalColor4 = FinalColor2_Blend_Screen * attenuation * LightColor;
				return float4(FinalColor3+ FinalColor4+SpecularLight + EmissionColor, _Alpha);
				}
				
			ENDCG
		}
		Pass{
			Name"ForwardAdd_forCustomLight多重光線衰弱(基底色)"
			Tags{
				"LightMode" = "ForwardAdd"
			}
			Blend One One
			Cull Off


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 
			#pragma multi_compile_fwdadd_fullshadows
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
///////參數材質建構:
			sampler2D _MainTex; float4 _MainTex_ST;
			sampler2D _SkinMask; float4 _SkinMask_ST;
			float _LdotN_Max; float _LdotN_Val; float OutLine_Width; float OutLine_CutOff; float _ColorChange;
			float4 _MainColor; float4 _ShadowColor; float4 _LightWrapColor;  float4 OutLine_Color; float4 _SkinColorChange;
///////模型資訊建構:
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float2 uv0 : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				UNITY_LIGHTING_COORDS(3,4)
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.uv0 = v.texcoord0;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			float4 frag(VertexOutput o, float facing : VFACE) : SV_Target{
				float FaceSign = (facing >= 0 ? 1 : -1);
				float3 LightColor = _LightColor0.rgb;
				float4 MainTex = tex2D(_MainTex, TRANSFORM_TEX(o.uv0, _MainTex));
				float4 SkinMask = tex2D(_SkinMask, TRANSFORM_TEX(o.uv0, _SkinMask));
				float3 NormalDir = normalize(o.normalDir)*FaceSign;
				float3 LightDir = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - o.posWorld.xyz, _WorldSpaceLightPos0.w));
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 ViewReflect = reflect(-ViewDir, NormalDir);
				float LdotVR = saturate(dot(LightDir, ViewReflect))*0.7 + 0.3;
////// Lighting:
				float attenuation = LIGHT_ATTENUATION(o);
				float LdotN = saturate(dot(LightDir, NormalDir));
				float LdotN_Attenuation = saturate(LdotN * attenuation);
				float LdotN_Att_SmoothStep = smoothstep(LdotN_Attenuation, (LdotN_Attenuation + _LdotN_Max), _LdotN_Val);
				if (_ColorChange == 1) {
					float3 MainTex_ColorChange = MainTex.rgb;
					float3 Blend_Overlay = saturate((_SkinColorChange.rgb > 0.5 ?
						(1 - ((1 - 2 * (_SkinColorChange.rgb - 0.5)))*(1 - MainTex_ColorChange.rgb)) :
						(2 * _SkinColorChange.rgb*MainTex_ColorChange.rgb)));
					float3 FinalColor = lerp(MainTex_ColorChange, Blend_Overlay, SkinMask.r);
					float3 FinalColor2 = lerp(FinalColor*_MainColor, FinalColor*_ShadowColor, float3(LdotN_Att_SmoothStep.xxx));
					float3 LightWrap = LdotVR * _LightWrapColor * FinalColor;
					float3 FinalColor3_Blend_Screen = saturate(1 - (1 - FinalColor2)*(1 - LightWrap));
					//float3 FinalColor4 = (1 - attenuation) * FinalColor3_Blend_Screen * LightColor; //光線衰落無法使用，推測為Additive模式下 雙重的光線疊加造成的問題 需要再研究
					float3 FinalColor5 = FinalColor3_Blend_Screen * attenuation * LightColor;
					return float4(FinalColor5 , 1);
				}
				else {
					float3 FinalColor = lerp(MainTex*_MainColor, MainTex*_ShadowColor, float3(LdotN_Att_SmoothStep.xxx));
					float3 LightWrap = LdotVR * _LightWrapColor * MainTex;
					float3 FinalColor2_Blend_Screen = saturate(1 - (1 - FinalColor)*(1 - LightWrap));
					//float3 FinalColor3 = (1 - attenuation)*FinalColor2_Blend_Screen*LightColor; //光線衰落無法使用，推測為Additive模式下 雙重的光線疊加造成的問題 需要再研究
					float3 FinalColor4 = FinalColor2_Blend_Screen * attenuation * LightColor;
					return float4(  FinalColor4, 1);
				}
			}
			ENDCG
		}
		Pass{
			Name"ShadowCaster陰影投射"
			Tags{
				"LightMode" = "ShadowCaster"
			}
			Offset 1,1
			Cull Off


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcaster
			#pragma target 3.0
			struct VertexInput {
				float4 vertex : POSITION;
			};
			struct VertexOutput{
				V2F_SHADOW_CASTER;
				// Declare all data needed for shadow caster pass output (any shadow directions/depths/distances as needed),
				// plus clip space position.
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_SHADOW_CASTER(o)
				return o;
			}
			float4 frag(VertexOutput o, float facing : VFACE) :SV_Target{
				float isFrontFace = (facing >= 0 ? 1 : 0);
				float faceSign = ( facing >= 0 ? 1 : -1 );
				SHADOW_CASTER_FRAGMENT(o)
			}
			ENDCG
		}
	}
}