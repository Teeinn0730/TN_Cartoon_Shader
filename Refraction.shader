Shader "TN/Refraction"{

	Properties{
		[Header(TexType)]
		[KeywordEnum(NormalMap,BlackTexture,AlphaTexture)] _UWT ("UseWhichType", Float) = 0
		_NormalMap( "NormalMap" , 2D ) = "white"{} 
		_BlackTexture( "BlackTexture" , 2D ) = "white"{} 
		_AlphaTexture( "AlphaTexture" , 2D ) = "white" {}
		_DistortIntensity("DistortIntensity", Range(-1,1)) = 0
		[Toggle] _TransparentImpact("TransparentImpact",Float) = 1
		_OpacityIntensity("OpacityIntensity",Float ) =  0
/////Blend Settings:
        [Header(Blend Settings)]
        [Enum(Off,0,Front,1,Back,2)] _Cull("CullMask",Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("Zwrite",Float) = 0
        [Enum(Less,0, Greater,1, LEqual,2, GEqual,3, Equal,4, NotEqual,5, Always,6)] _ZTest ("ZTest", Float) = 2
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
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
			CGPROGRAM
				//pragma 定義項目
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				#pragma shader_feature _UWT_NORMALMAP _UWT_BLACKTEXTURE _UWT_ALPHATEXTURE
				//uniform 重整所有參數
				uniform sampler2D _GrabpassTex ;
				uniform sampler2D _NormalMap ; uniform float4  _NormalMap_ST;
				uniform sampler2D _BlackTexture ; uniform float4  _BlackTexture_ST;
				uniform sampler2D _AlphaTexture ; uniform float4 _AlphaTexture_ST;
				float _DistortIntensity;
				float _OpacityIntensity;
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
				VertexOutput vert (VertexInput v){
					VertexOutput o ;
					o.uv = v.uv ;
					o.vertexColor = v.vertexColor ;
					o.vertex = UnityObjectToClipPos( v.vertex ) ;
					o.projPos = ComputeScreenPos ( o.vertex );
					COMPUTE_EYEDEPTH(o.projPos.z);
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
					float BlackTexture_VertexAlpha =saturate(lerp((BlackTexture_Value.r*o.vertexColor.a*_OpacityIntensity),BlackTexture_Value.r*_OpacityIntensity,_TransparentImpact));
					return fixed4 (BlackTexture_Final,BlackTexture_VertexAlpha) ;
				//使用法線貼圖時:
				#elif _UWT_NORMALMAP
					float4 NormalMap_Value = tex2D( _NormalMap ,TRANSFORM_TEX(o.uv ,_NormalMap) ) ; 
					float2 NormalMap_Value2 = (NormalMap_Value.rg-0.5)*2 ;
					NormalMap_Value2.r *= -1;
					float2 NormalMap_Value3 = float2 ( NormalMap_Value2 * _DistortIntensity ) + ( sceneUVs );
					float2 NormalMap_Value4 = lerp ( sceneUVs , NormalMap_Value3 , o.vertexColor.a ) ;
					float3 NormalMap_Final = tex2D( _GrabpassTex , NormalMap_Value4 ) ;
					float NomalMap_Alpha = saturate(dot(float3( NormalMap_Value2.r , NormalMap_Value2.g , 0) , float3(0.3,0.59,0.11) )); 
					float NormalMap_VertexColor = lerp((NomalMap_Alpha * o.vertexColor.a * _OpacityIntensity) , (NomalMap_Alpha * _OpacityIntensity) , _TransparentImpact );
					return fixed4 (NormalMap_Final,NormalMap_VertexColor) ; 
				//使用透明貼圖時: 
				#elif _UWT_ALPHATEXTURE
					float4 AlphaTexture_Value = tex2D( _AlphaTexture ,TRANSFORM_TEX(o.uv ,_AlphaTexture) ) ; 
					float AlphaTexture_Value2 = dot(AlphaTexture_Value.rgb,float3(0.3,0.59,0.11));
					float2 AlphaTexture_Value2_2 = float2( -AlphaTexture_Value2*UVCoord.r , AlphaTexture_Value2*UVCoord.g );
					float2 AlphaTexture_Value3 = float2 ( AlphaTexture_Value2_2 * _DistortIntensity ) + ( sceneUVs );
					float2 AlphaTexture_Value4 = lerp ( sceneUVs , AlphaTexture_Value3 , o.vertexColor.a ) ;
					float3 AlphaTexture_Final = tex2D( _GrabpassTex , AlphaTexture_Value4 ) ;
					float AlphaTexture_VertexColor = saturate(lerp((AlphaTexture_Value.a * o.vertexColor.a*_OpacityIntensity) , (AlphaTexture_Value.a*_OpacityIntensity) , _TransparentImpact ));
					return fixed4 (AlphaTexture_Final,AlphaTexture_VertexColor) ; 
				#endif
					return fixed4(1,1,1,1);
				}
			ENDCG
		}
	}

}