Shader "TN/Cartoon_Shader"
{
	Properties
	{
		[Header(ShadowProp     ShadowProp     ShadowProp )][Space][Space]
		_LdotN_Max("SmoothShadow",Range(0,1)) = 0.1
		_LdotN_Val("ShadowProportion",Range(0,1)) = 0.5
		[Header(MainTexProp     MainTexProp     MainTexProp)][Space][Space]
		_MainTex("MainTex", 2D) = "white" {}
		[HDR]_MainColor("MainTexColor",Color) = (1,1,1,1)
		_ShadowColor("ShadowColor",Color) = (0.8,0.8,0.8,1)
		_LightWrapColor("LightWrapColor",Color) = (0,0,0,0)
		[Header(OutLineProp     OutLineProp     OutLineProp)][Space][Space]
		_OutLine_Width("OutLineScale",Range(0,1)) = 0
		_OutLine_Color("OutLineColor",Color) = (0,0,0,0)
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
			"RenderType"="Transparent"
		}
		Pass{
			Name"OutLine描邊"
			Tags{
				//No LightMode
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
			float _OutLine_Width ;
			float4 _OutLine_Color;
			float _ColorChange;
			float4 _SkinColorChange;
			float _OutLine_CutOff;
///////模型資訊建構:
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float3 normal : NORMAL;
				float4 posWorld : TEXCOORD1;
			};
			VertexOutput vert(VertexInput i) {
				VertexOutput o;
				o.uv0 = i.texcoord0;
				o.normal = normalize(UnityObjectToWorldNormal(i.normal));
				o.pos = UnityObjectToClipPos(float4(i.vertex.xyz + i.normal*_OutLine_Width, 1));
				o.posWorld = mul(unity_ObjectToWorld , i.vertex);
				return o;
			}
			float4 frag(VertexOutput o) : SV_Target{
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float VdotN = saturate(dot(-ViewDir, o.normal));
				if (VdotN > _OutLine_CutOff) { 
					discard; //不繪製的意思;
				}
				float4 OutLineColor = tex2D(_MainTex , TRANSFORM_TEX(o.uv0,_MainTex));
				float3 OutLineColor2 = OutLineColor.rgb * _OutLine_Color;
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
			float _LdotN_Max; float _LdotN_Val; float OutLine_Width; float OutLine_CutOff; float _ColorChange; float _Alpha;
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
				LIGHTING_COORDS(3,4)
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.uv0 = v.texcoord0;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			float4 frag ( VertexOutput o, float facing : VFACE) : SV_Target {
				float3 LightColor = _LightColor0.rgb;
				float faceSign = (facing >= 0 ? 1 : -1);
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 NormalDir = o.normalDir = normalize(o.normalDir)*faceSign;
				float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
				float attenuation = LIGHT_ATTENUATION(o);
////// Emissive:
				float4 MainTex = tex2D(_MainTex, TRANSFORM_TEX(o.uv0, _MainTex));
				float4 SkinMask = tex2D(_SkinMask, TRANSFORM_TEX(o.uv0, _SkinMask));
				float LdotN = saturate(dot(LightDir, NormalDir));
				float LdotN_Attenuation = saturate(LdotN * attenuation); 
				float LdotN_Att_SmoothStep = smoothstep(LdotN_Attenuation, (LdotN_Attenuation + _LdotN_Max), _LdotN_Val);
				float3 ViewReflect = reflect(-ViewDir,NormalDir);
				float LdotVR = saturate(dot(LightDir, ViewReflect))*0.7+0.3;
				if (_ColorChange == 1) {
					float3 MainTex_ColorChange = MainTex.rgb;
					float3 Blend_Overlay = saturate( (_SkinColorChange.rgb > 0.5 ?
						(1 -((1 - 2 * (_SkinColorChange.rgb - 0.5)))*(1 - MainTex_ColorChange.rgb)) :
						(2 * _SkinColorChange.rgb*MainTex_ColorChange.rgb)) );
					float3 FinalColor = lerp(MainTex_ColorChange, Blend_Overlay, SkinMask.r);
					float3 FinalColor2 = lerp(FinalColor*_MainColor, FinalColor*_ShadowColor, float3(LdotN_Att_SmoothStep.xxx));
					float3 LightWrap = LdotVR * _LightWrapColor * FinalColor; 
					float3 FinalColor3_Blend_Screen = saturate(1 - (1 - FinalColor2)*(1 - LightWrap));
					float3 FinalColor4 = (1 - attenuation) * FinalColor3_Blend_Screen * LightColor;
					float3 FinalColor5 = FinalColor3_Blend_Screen * attenuation * LightColor;
					return float4(Blend_Overlay, _Alpha);
					}
				else {
					float3 FinalColor = lerp(MainTex*_MainColor, MainTex*_ShadowColor, float3(LdotN_Att_SmoothStep.xxx));
					float3 LightWrap = LdotVR * _LightWrapColor * MainTex;
					float3 FinalColor2_Blend_Screen = saturate(1-(1- FinalColor)*(1- LightWrap));
					float3 FinalColor3 = (1 - attenuation)*FinalColor2_Blend_Screen*LightColor;
					float3 FinalColor4 = FinalColor2_Blend_Screen * attenuation * LightColor;
					return float4(FinalColor3+ FinalColor4, _Alpha);
					}
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