Shader "TN/Refraction"{
	Properties{
		[Header(TexType)]
		[KeywordEnum(NormalMap,BlackTexture,AlphaTex)] _UWT ("UseWhichType", Float) = 0
		_NormalMap( "NormalMap" , 2D ) = "white"{} 
		_BlackTexture( "BlackTexture" , 2D ) = "white"{} 
		_AlphaTexture( "AlphaTexture" , 2D ) = "white" {}
		_DistortIntensity("DistortIntensity", Range(-1,1)) = 0
		[Toggle] _TransparentImpact("TransparentImpact",Float) = 1
		_OpacityIntnsity("OpacityIntensity",Float ) =  0
	}
	SubShader{
		
		Tags{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector" = " True "
		}

		GrabPass{ 
			"_GrabpassTex"
		}

		Pass{

			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			ZWrite Off

			CGPROGRAM
				//pragma 定義項目
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				#pragma shader_feature _UWT_NORMALMAP _UWT_BLACKTEXTURE _UWT_ALPHATEX
				 
				//uniform 重整所有參數
				uniform sampler2D _GrabpassTex ;
				uniform sampler2D _NormalMap ; uniform float4  _NormalMap_ST;
				uniform sampler2D _BlackTexture ; uniform float4  _BlackTexture_ST;
				uniform sampler2D _AlphaTexture ; uniform float4 _AlphaTexture_ST;
				float _DistortIntensity;
				float _OpacityIntnsity;
				float _TransparentImpact;

				// 建構函數
				struct VertexInput{
					float4 vertex : POSITION ;
					float2 uv : TEXCOORD0 ;
					float4 vertexColor : COLOR ;
				};
				struct VertexOutput{
					float4 vertex : SV_POSITION ;
					float2 uv : TEXCOORD0 ;
					float4 vertexColor : COLOR ;
					float4 projPos : TEXCOORD1 ;
				};
				VertexOutput vert (VertexInput i){
					VertexOutput o ;
					o.uv = i.uv ;
					o.vertexColor = i.vertexColor ;
					o.vertex = UnityObjectToClipPos( i.vertex ) ;
					o.projPos = ComputeScreenPos ( o.vertex );
					//COMPUTE_EYEDEPTH(o.projPos.z);
					return o;
				}

				float4 frag ( VertexOutput o ) : COLOR {
					float2 sceneUVs = (o.projPos.xy/o.projPos.w) ;
					float4 sceneColor = tex2D ( _GrabpassTex , sceneUVs ) ;
				//Fill Color:
					float2 UVCoord = (o.uv*2 - 1) ;
				//使用黑底貼圖時:
				#if _UWT_BLACKTEXTURE
					float2 BlackTexture_Value = tex2D( _BlackTexture ,TRANSFORM_TEX(o.uv ,_BlackTexture) ) ; 
					float2 BlackTexture_Value2 = float2( -1*(BlackTexture_Value.r * UVCoord.r) , BlackTexture_Value.g * UVCoord.g ) ; 
					float2 BlackTexture_Value3 = float2 ( BlackTexture_Value2 * _DistortIntensity ) + ( sceneUVs );
					float2 BlackTexture_Value4 = lerp ( sceneUVs , BlackTexture_Value3 , o.vertexColor.a ) ;
					float3 BlackTexture_Final = tex2D(_GrabpassTex , BlackTexture_Value4 );
					float BlackTexture_VertexAlpha = lerp((BlackTexture_Value.r*o.vertexColor.a),BlackTexture_Value.r,_TransparentImpact);
					return fixed4 (BlackTexture_Final,BlackTexture_VertexAlpha) ;
				//使用法線貼圖時:
				#elif _UWT_NORMALMAP
					float4 NormalMap_Value = tex2D( _NormalMap ,TRANSFORM_TEX(o.uv ,_NormalMap) ) ; 
					float2 NormalMap_Value2 = float2( -1*(NormalMap_Value.r * UVCoord.r) , NormalMap_Value.g * UVCoord.g ) ;
					float2 NormalMap_Value3 = float2 ( NormalMap_Value2 * _DistortIntensity ) + ( sceneUVs );
					float2 NormalMap_Value4 = lerp ( sceneUVs , NormalMap_Value3 , o.vertexColor.a ) ;
					float3 NormalMap_Final = tex2D( _GrabpassTex , NormalMap_Value4 ) ;
					float NormalMap_VertexColor = lerp((NormalMap_Value.a * o.vertexColor.a) , (NormalMap_Value.a) , _TransparentImpact );
					return fixed4 (NormalMap_Final,NormalMap_VertexColor) ; 
				//使用透明貼圖時:
				#elif _UWT_ALPHATEX
					float4 AlphaTexture_Value = tex2D( _AlphaTexture ,TRANSFORM_TEX(o.uv ,_AlphaTexture) ) ; 
					float2 AlphaTexture_Value2 = float2( -1*(AlphaTexture_Value.r * UVCoord.r) , AlphaTexture_Value.g * UVCoord.g ) ;
					float2 AlphaTexture_Value3 = float2 ( AlphaTexture_Value2 * _DistortIntensity ) + ( sceneUVs );
					float2 AlphaTexture_Value4 = lerp ( sceneUVs , AlphaTexture_Value3 , o.vertexColor.a ) ;
					float3 AlphaTexture_Final = tex2D( _GrabpassTex , AlphaTexture_Value4 ) ;
					float AlphaTexture_VertexColor = lerp((AlphaTexture_Value.a * o.vertexColor.a) , (AlphaTexture_Value.a) , _TransparentImpact );
					return fixed4 (AlphaTexture_Final,AlphaTexture_VertexColor) ; 
				#endif
				}
			ENDCG
		}
	}
}