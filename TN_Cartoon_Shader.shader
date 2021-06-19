Shader "TN/Cartoon_Shader"
{
	Properties
	{
		[Header(ShadowProp     ShadowProp     ShadowProp )][Space][Space]
		_LdotN_Start("LdotN_Start(陰影起點)",Range (0,1)) = 0
		_LdotN_End("LdotN_End(陰影終點)",Range (0,1)) = 1
		[Header(MainTexProp     MainTexProp     MainTexProp)][Space][Space]
		_MainTex("MainTex(主要貼圖)", 2D) = "black" {}
		_NormalMap("NormalMpa(法線貼圖)" , 2D) = "bump"{}
		_Normal_Intensity("Normal_Intensity(法線強度)" , Range(0,10)) =1
		[HDR] _MainColor ("MainTexColor(主貼圖顏色)",Color) = (1,1,1,1)
		[HDR] _ShadowColor("ShadowColor(主陰影顏色)",Color) = (0.8,0.8,0.8,1)
		[HDR] _ShadowColor2("ShadowColor2(副陰影顏色)",Color) = (0.8,0.8,0.8,1)
		_ShadowMap("ShadowMap(拆影遮罩R+手繪陰影G+高光遮罩B)",2D) = "black"{}
		[MaterialToggle] _useShadowMap_R ("useShadowMap_R(分開兩種不同物件的陰影顏色)",Float) = 0 /////ShadowMap 的R通道: 分開兩種不同物件的陰影顏色(e.g 皮膚與衣服的陰影顏色) 
		[MaterialToggle] _useShadowMap_G ("useShadowMap_G(陰影遮蔽區域//e.g 腋下、脖子、奶子下方)",Float) = 0 /////ShadowMap 的G通道: 陰影遮蔽區域(e.g 腋下、脖子、奶子下方，都是平常光照不到的地方，可以直接手繪方式去做硬陰影(參考原神)) 
		[MaterialToggle] _useShadowMap_B ("useShadowMap_B(頭髮高光區域)",Float) = 0 /////ShadowMap 的B通道: 頭髮高光區域
		[HDR] _LightHair_Color ("LightHair_Color(頭髮高光顏色)",Color) = (1,1,1,1)
		_Metal_Spec_Emi_Map("Metal_Specualr_Emission Map(金屬R+發光貼圖B)",2D) = "white"{}
		[MaterialToggle] _useMetalMask ("useMetalMask(金屬物品遮罩)",Float) = 0
		//[MaterialToggle] _useSpecularMask ("useSpecularMask(暫未使用)",Float) = 0
		[MaterialToggle] _useEmissionlMask ("useEmissionMask(發光遮罩)",Float) = 0
		_Specular_pow("Specular(高光範圍)",Range(0.1,1))=0.1
		_Metal_Intensity("Metal_Intensity(金屬高光強度)",Range(0,10)) = 1
		_Emission_Color("Emission_Color(發光顏色)",Color) = (1,1,1,1)
		[Header(Light     Light     Light)][Space][Space]
		_LightWrap_Start("LightWrap_Start(環繞色起點)" , Range (-1,1)) = 0
		_LightWrap_End("LightWrap_End(環繞色終點)" , Range (-1,1))=0
		_LightWrap1("LightWrap1(主環繞色)",Color) = (0,0,0,0)
		_LightWrap2("LightWrap2(副環繞色)",Color) = (0,0,0,0)
		_FresnelColor("FresnelColor(背光顏色)",Color) = (0,0,0,0)
		_Fresnel_Start("Fresnel_Start(背光範圍1)",Range(0,1)) = 0
		_Fresnel_End("Fresnel_End(背光範圍2)",Range(0,1)) = 1
		[Header(OutLineProp     OutLineProp     OutLineProp)][Space][Space]
		[MaterialToggle] _useTangentNormal ("useTangentNormal(使用特殊法線製作描邊才打勾)",Float) = 0
		_OutLine_Width("OutLineWidth(描邊粗細)",Range(0,100)) = 0
		_OutLine_Color("OutLineColor(主描邊顏色)",Color) = (0,0,0,0)
		_OutLine_Color2("OutLineColor2(副描邊顏色)",Color) = (0,0,0,0)
		_OutLine_CutOff("OutLineCutStep(描邊裁切//用於透明物體)",Range(-0.1,1)) = 0.5
		[Header(AlphaProp     AlphaProp     AlphaProp)][Space][Space]
		_Alpha("Alpha(透明度)",Range(0,1)) = 1
		[Header(SpecialProp     SpecialProp     SpecialProp)][Space][Space]
		_Special_Mask("SpecialMask(特殊遮罩// R:換膚色 G:霓光 )",2D) = "black"{}
		[HDR] _SkinColor2("SkinColor2(Alpha可控制)",Color) = (1,1,1,1)
		_NieoLight_Color("NieoLight_Color(Alpha可控制)",Color) = (1,1,1,1)
		/*
		_ShyPos("ShyPos",Range(0,1)) = 0
		_ShySmooth("ShySmooth",Range(0,1)) = 0
		[HDR]_ShyColor("ShyColor",Color) = (1,1,1,1)
        _Mask("Mask",2D) = "white"{}
		*/
		[Header(Stencil Settings)][Space][Space]
        _Ref ("Ref",Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _Comp ("Comparison",Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _Pass ("Pass ",Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _Fail ("Fail ",Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _ZFail ("ZFail ",Float) = 0
		/*
		_HSVRangeMin ("HSV Affect Range Min", Range(0, 1)) = 0
		_HSVRangeMax ("HSV Affect Range Max", Range(0, 1)) = 1
		_HSVAAdjust ("HSVA Adjust", Vector) = (0, 0, 0, 0)
		*/
	}

	SubShader{
		Tags{
			"Queue" = "Geometry"
		}
		Pass{
			Name"OutLine描邊"
			Tags{
			}
			Cull Front //有Pass在前面的話則不渲染
			ZWrite On
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
			sampler2D _ShadowMap ;
			float _OutLine_CutOff , _useTangentNormal , _useShadowMap_R , _OutLine_Width , _useShadowMask  ; 
			float4 _OutLine_Color , _OutLine_Color2 , _SkinColor2;
///////模型資訊建構:
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float3 color : COLOR;
				float2 texcoord0 : TEXCOORD0;
				};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float3 normal : NORMAL;
				float4 posWorld : TEXCOORD1;
				};
			VertexOutput vert(VertexInput i) {
				VertexOutput o = (VertexOutput) 0;
				if(_OutLine_Width == 0){
					return o;
				}
				o.uv0 = i.texcoord0;
				float3 AverageNormal = _useTangentNormal*i.tangent.xyz + (1-_useTangentNormal)*i.normal.xyz; 
				float3 clipnormal =mul((float3x3)UNITY_MATRIX_MVP , AverageNormal.xyz );
				o.pos = UnityObjectToClipPos(i.vertex);
				float2 offset = normalize(clipnormal.xy) / _ScreenParams.xy * _OutLine_Width *o.pos.w * i.color.r;
				o.pos.xy +=offset;
				o.posWorld = mul(unity_ObjectToWorld , i.vertex);
				o.normal = normalize(UnityObjectToWorldNormal( AverageNormal ));
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
////// InverseLerp function:
			float InverseLerp (float a , float b , float c ) {
				return saturate((c-a)/(b-a));
			}
////// Frag:
			float4 frag(VertexOutput o) : SV_Target{
				if(_OutLine_Width == 0){
					discard;
					return 0;
				}
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float VdotN = saturate(dot(-ViewDir, o.normal));
				VdotN = -1* InverseLerp(_OutLine_CutOff,1,VdotN);
				clip (VdotN) ;
				float4 OutLineColor = tex2Dlod(_MainTex , float4(TRANSFORM_TEX(o.uv0,_MainTex),0,5));
				float3 OutLineColor2 = OutLineColor.rgb * _OutLine_Color;
////// 部分配件使用貼圖更換描邊的顏色:
				float ShadowMask = tex2D( _ShadowMap , o.uv0 ).r;
				OutLineColor2 = OutLineColor.rgb * lerp( _OutLine_Color.rgb , _OutLine_Color2.rgb , ShadowMask*_useShadowMap_R);
////// 輸出顏色:
				return float4 ( OutLineColor2.rgb , 1) ;
			}
			ENDCG
		}
		
		Pass{
			Name "ForwardBase基底色"
			Tags{
				"LightMode" = "ForwardBase"
			}
			Stencil {
				Ref [_Ref]          //0-255
				Comp [_Comp]     //default:always
				Pass [_Pass]   //default:keep
				Fail [_Fail]      //default:keep
				ZFail [_ZFail]     //default:keep
			}
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Back
			ZWrite On
			CGPROGRAM
///////pragma參數設定:
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
///////參數材質建構:
			sampler2D _MainTex , _ShadowMap , _Metal_Spec_Emi_Map , _NormalMap , _Special_Mask;
			float4 _MainTex_ST , _NormalMap_ST , _Special_Mask_ST;
			float _LdotN_End, _LdotN_Start , OutLine_Width , OutLine_CutOff , _ColorChange , _Alpha , _useShadowMap_R ,  _useShadowMap_G ,  _useShadowMap_B , _Fresnel_Start , _Fresnel_End , _Specular_pow , _useMetalMask , _useSpecularMask , _useEmissionlMask  , _Metal_Intensity , _LightWrap_Start, _LightWrap_End  , _Normal_Intensity  ;
			float4 _MainColor , _ShadowColor , _ShadowColor2 , _FresnelColor , OutLine_Color , _SkinColorChange , _LightWrap1 , _LightWrap2 , _LightHair_Color , _NieoLight_Color , _SkinColor2 , _Emission_Color; 
////// 建構RGB2HSV函式:
/*
			float3 rgb2hsv(float3 c) {
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
            } 
*/
////// 建構Screen函式:
			float3 ScreenFunc( float3 a , float3 b ){
				return saturate(max(a,b));
			}
////// 建構Overlay函式:
			float3 OverlayFunc( float3 a , float3 b ){
				return saturate(1-(1-a)*(1-b));
			}
////// 建構Hue函式:
			float3 Hue( float3 a ){
				return saturate(3*abs(1-2*frac(a+float3(0,0.33,0.66)))-1);
			}
///////模型資訊建構:
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
				float4 tangent : TANGENT;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float2 uv0 : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				LIGHTING_COORDS(3,4)
				float3 tangentDir : TEXCOORD5;
				float3 bitangentDir : TEXCOORD6;
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = normalize(UnityObjectToWorldNormal(v.normal));
				o.uv0 = v.texcoord0;
				o.tangentDir = UnityObjectToWorldNormal(v.tangent);
				o.bitangentDir = cross(o.normalDir,o.tangentDir) * v.tangent.w;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
////// InverseLerp function:
			float InverseLerp (float a , float b , float c ) {
				return saturate((c-a)/(b-a));
			}
////// Frag:
			float4 frag ( VertexOutput o, float facing : VFACE) : SV_Target {
				float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 NormalDir = (o.normalDir);
				float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
////// Lighting:
				//UNITY_LIGHT_ATTENUATION(attenuation, o, o.posWorld.xyz); //因為Direcation Light也就是太陽光 並沒有像點光源一樣的球形衰弱計算 所以不用賦予這個值在ForwardBase裡面。
				//float attenuation = LIGHT_ATTENUATION(o); // 新版定義: UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
////// Texture2D:
				float4 MainTex = tex2D(_MainTex, TRANSFORM_TEX(o.uv0, _MainTex));
				float4 ShadowMap = tex2D( _ShadowMap , o.uv0 ); 
				float4 SpecialMask = tex2D( _Special_Mask , TRANSFORM_TEX(o.uv0 , _Special_Mask));
//////NormalMap: 
				float3 NormalMap = UnpackNormal(tex2D(_NormalMap , TRANSFORM_TEX(o.uv0,_NormalMap)));
				NormalMap.rg *=_Normal_Intensity;
				float3x3 tangentTransform = float3x3(o.bitangentDir,o.tangentDir,o.normalDir);
				NormalDir = normalize(mul(NormalMap , tangentTransform));
////// Light Dot Normal / View Dot Normal:
				float VdotN = dot( ViewDir , NormalDir );
				float LdotN = saturate(dot(LightDir, NormalDir));
				LdotN = _useShadowMap_G*LdotN*(1-ShadowMap.g) + (1-_useShadowMap_G)*LdotN;
				float LdotN_Att_SmoothStep = InverseLerp(_LdotN_Start,_LdotN_End,LdotN);
				float LdotN_Att_SmoothStep_smooth = InverseLerp(_LdotN_Start+_LightWrap_Start,_LdotN_End+_LightWrap_End,LdotN); //for lightwrap
				float3 ViewReflect = reflect(-ViewDir,NormalDir);
				float LdotVR = saturate(dot(LightDir, ViewReflect))*0.7+0.3; // Metal Light
////// Shadow Color:
				float3 ShadowColor =  ( _useShadowMap_R * lerp( _ShadowColor.rgb , _ShadowColor2.rgb , ( ShadowMap.r )) + (1-_useShadowMap_R) * _ShadowColor.rgb )* MainTex;
////// Emission:
				float4 Metal_Spec_Emi_tex = tex2D( _Metal_Spec_Emi_Map , o.uv0 );
				float3 EmissionColor = _useEmissionlMask * Metal_Spec_Emi_tex.b * MainTex.rgb * saturate(sin(_Time.g)) * _Emission_Color.rgb * _Emission_Color.a ;
////// Back Light:
				float Fresnel =1-max(0,(dot( ViewDir , NormalDir )));
				Fresnel = InverseLerp( _Fresnel_Start , _Fresnel_End , Fresnel) ;
				float VdotL = saturate(dot( LightDir , -ViewDir ));
				float LightWrap = Fresnel*VdotL;
////// Metal Light:
				float3 halfLight = normalize( LightDir + ViewDir );
				float3 HLdotN = (saturate(dot(halfLight,NormalDir)));
				float3 MetalLight = _useMetalMask * Metal_Spec_Emi_tex.r * _LightColor0.rgb * pow(HLdotN , _Specular_pow *100)*_Metal_Intensity;
////// Hair Light:
				float3 LightHair = _useShadowMap_B * pow(HLdotN , 5) * ShadowMap.b * _LightHair_Color ;
////// Final Color:
				float3 FinalColor = MainTex*_MainColor ;
////// VividLight:
				float3 Overlay =  (LdotN_Att_SmoothStep_smooth*(1-LdotN_Att_SmoothStep_smooth)) * FinalColor;
				Overlay = Overlay * lerp( _LightWrap1.rgb  , _LightWrap2.rgb  , ShadowMap.r*_useShadowMap_R) * _LightColor0.rgb;
				FinalColor = lerp( FinalColor , ShadowColor, float3(LdotN_Att_SmoothStep.xxx));
				FinalColor = FinalColor + Overlay ;
////// Skin Color Change:
				FinalColor = lerp(FinalColor.rgb , dot(FinalColor,float3(0.3,0.59,0.11).xxx )*_SkinColor2.rgb , SpecialMask.r*_SkinColor2.a );
////// LightWrap (BackLight):
				float3 BackLight = LightWrap * _FresnelColor * MainTex;
				float3 FinalColor2_Blend_Screen = saturate(1-(1- FinalColor)*(1- BackLight));
////// Nieo Light:
				float3 NieoLight = Hue(VdotN);
				NieoLight = OverlayFunc(NieoLight,_NieoLight_Color)*_NieoLight_Color.a*SpecialMask.g;
////// Final Color :
				float3 FinalColor3 = FinalColor2_Blend_Screen * _LightColor0.rgb;
				FinalColor3 = FinalColor3 + MetalLight + EmissionColor + LightHair + NieoLight ;
				return float4( FinalColor3 , _Alpha);
				}
			ENDCG
		}
		Pass{
			Name"ForwardAdd點光源"
			Tags{
				"LightMode" = "ForwardAdd" 
			}
			Blend One One
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 
			#pragma target 3.0
			#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma multi_compile_fwdadd //指令保证Shader中访问正确的光照变量
			//#pragma multi_compile_fwdadd_fullshadows //Additional Pass中渲染的光源默认情况没有阴影效果，需要使用 #pragma multi-compile-fwdadd-fullshadows代替 #pragma multi-compile-fwdadd编译指令。
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
///////參數材質建構:
			sampler2D _MainTex ; 
			float4 _MainTex_ST , _MainColor ;
			float _Alpha;
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
				UNITY_LIGHTING_COORDS(2,3)
			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.uv0 = v.texcoord0;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			float4 frag(VertexOutput o, float facing : VFACE) : SV_Target{
////// Lighting:
				UNITY_LIGHT_ATTENUATION(attenuation, o, o.posWorld.xyz); 
////// Texture:
				float4 MainTex = tex2D(_MainTex, TRANSFORM_TEX(o.uv0, _MainTex));
////// Final Color:
				float3 FinalColor = MainTex.rgb*_MainColor.rgb ;
				FinalColor  *= _LightColor0.rgb * attenuation ;
////// Final Color :
				return float4( FinalColor.rgb , attenuation*_Alpha );
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