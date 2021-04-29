Shader "TN/Particle Settings"
{
    Properties{
        [Header(Properties)]
        _X_Speed ("X_Speed", Float ) = 0
        _Y_Speed ("Y_Speed", Float ) = 0
        [MaterialToggle] _SceneUV ("SceneUV", Float ) = 0
        _MainTex ("MainTex", 2D) = "white" {}
        [HDR]_MainColor ("MainColor", Color) = (0.5,0.5,0.5,1)
        [MaterialToggle] _Fresnel ("Fresnel", Float ) = 0
        _Fresnel_Range ("Fresnel_Range", Range(0, 5)) = 1
        _Fresnel_Intensity ("Fresnel_Intensity", Range(0, 5)) = 1
        [HDR]_Fresnel_Color ("Fresnel_Color", Color) = (0.5,0.5,0.5,1)
/////Blend Settings:
        [Header(Blend Settings)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SourceBlend ("SrcBlend",Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _DestBlend ("DestBlend",Float) = 0
        [Enum(Off,0,Front,1,Back,2)] _Cull("CullMask",Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("Zwrite",Float) = 0
        [Enum(Less,0, Greater,1, LEqual,2, GEqual,3, Equal,4, NotEqual,5, Always,6)] _ZTest ("ZTest", Float) = 2
/////interupte uv:
        [Header(Interupte UV)]
        [MaterialToggle] _InterupteToggle ("InterupteToggle", Float ) = 0
        _InterupteTex("interupteTex",2D) = "white"{}
        _InterupteValue("interupteValue",Range(0,1)) = 0
/////Desaturate:
        [Header(Desaturate)]
        [MaterialToggle] _desaturate ("Desaturate", Float ) = 0
        [HDR]_desaturateColor("DesaturateColor",Color)=(1,1,1,1)
/////ReColor_Gradient:
        [Header(ReColor_Gradient)]
        [MaterialToggle] _colorGradient("ColorGradient(need to use Desaturate)",Float) = 0
        _GradientValue("GradientValue",Range(0,1)) = 0.5
        [HDR] _color1("BrightColor",Color) = (1,1,1,1)
        [HDR] _color2("DarkColor",Color) = (0.5,0.5,0.5,1)
/////UVTile:
        [Header(Sequence For Trail)]
        [MaterialToggle] _UseUVtile("UseUVTile",Float) = 0
        _UVtileXY ("UVTile",Vector) = (0,0,0,0)
        _UVtileSpd ("UVTileSpd" , Float) = 0
/////UVRotator:
        [Header(UV Rotator)]
        [MaterialToggle] _UseUVRotator ("UseUVRotator", Float) = 0
        _UVRotator_Angle ("Rotator" , Float) = 0
/////Facing:
        [Header(FaceColor)]
        [MaterialToggle] _UseFacing ("UseFacing?",Float) = 0
        [HDR] _BackColor ("BackColor" ,Color) = (0.5,0.5,0.5,1)
/////Stencil Settings:
        [Header(Stencil Settings)]
        _Ref ("Ref",Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _Comp ("Comparison",Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _Pass ("Pass ",Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _Fail ("Fail ",Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _ZFail ("ZFail ",Float) = 0
        
    }
    SubShader{
        Tags{
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        
        Stencil {
             Ref [_Ref]          //0-255
             Comp [_Comp]     //default:always
             Pass [_Pass]   //default:keep
             Fail [_Fail]      //default:keep
             ZFail [_ZFail]     //default:keep
        }
        Pass{
            Tags{
                "LightMode"="ForwardBase"
            }
            Blend [_SourceBlend] [_DestBlend]
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma target 3.0

            struct VertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 vertexColor : COLOR;
                float4 uv : TEXCOORD0;
            };
            struct VertexOutput{
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 projPos : TEXCOORD2;
                float4 vertexColor : COLOR;
            };

            sampler2D _MainTex ; float4 _MainTex_ST; sampler2D _InterupteTex; float4 _InterupteTex_ST;
            float _X_Speed; float _Y_Speed; float _Fresnel_Range; float _Fresnel_Intensity; float _Fresnel; float _SceneUV; float _InterupteValue; float _InterupteToggle; float _desaturate; float _colorGradient; float _GradientValue; float _UseUVtile; float _UVtileSpd; float _UseFacing; float _UseUVRotator; float _UVRotator_Angle;
            float4 _MainColor; float4 _Fresnel_Color; float4 _desaturateColor; float4 _color1; float4 _color2; float4 _UVtileXY; float4 _BackColor;

            VertexOutput vert (VertexInput v ){
                VertexOutput o = (VertexOutput)0;
                o.vertexColor = v.vertexColor;
                o.normal = UnityObjectToWorldNormal(v.normal); 
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld,v.vertex);
                if(_SceneUV){
                    o.projPos = ComputeScreenPos(o.pos);
                    COMPUTE_EYEDEPTH(o.projPos.z);
                }
                else{
                     o.projPos = v.uv;
                }
                return o;
            }

            float4 frag(VertexOutput o, float facing : VFACE) : SV_Target{
                o.normal = normalize(o.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz-o.posWorld.xyz);
/////////Facing:
                float3 FaceColor = 1;
                if(_UseFacing){ FaceColor = (facing >= 0 ? _BackColor : 1); }
                //float isFrontFace = ( facing >= 0 ? 1 : 0 );
                //float faceSign = ( facing >= 0 ? 1 : -1 );
/////////UVTile:
                float UVTile_TimeSpeed , UVTile_X , UVTile_Y= 0 ; float2 UVTile =0;
                if(_UseUVtile){
                    UVTile_TimeSpeed = trunc(_Time.g *  _UVtileSpd);
                    UVTile = float2 (1,1) / float2 (_UVtileXY.x,_UVtileXY.y);
                    UVTile_X = floor(UVTile_TimeSpeed * UVTile.x);
                    UVTile_Y = 1-( UVTile_TimeSpeed - _UVtileXY.y * UVTile_X);
                }
/////////SceneUV :
                float2 SceneUV = o.projPos.xy / o.projPos.w; 
                if(_InterupteToggle){
                    float2 InterupteUV = o.projPos.xy / o.projPos.w;
                    InterupteUV += float2(_X_Speed,_Y_Speed)*_Time.g;

                    float4 InterupteTex = tex2D(_InterupteTex,TRANSFORM_TEX(InterupteUV,_InterupteTex));
                    SceneUV = lerp( SceneUV , InterupteTex.rg , _InterupteValue );
                }
                else{
                    SceneUV += float2(_X_Speed,_Y_Speed)*_Time.g;
                }
                if(_UseUVtile){
                    SceneUV = (SceneUV+float2(UVTile_X,UVTile_Y)) * UVTile;
                }
/////////UV Rotator:
                float UVRotator_cos , UVRotator_sin = 0;
                if(_UseUVRotator){
                    UVRotator_cos = cos(_UVRotator_Angle * _Time.g);
                    UVRotator_sin = sin(_UVRotator_Angle * _Time.g);
                    float2 Pivot = float2(0.5,0.5);
                    SceneUV = mul( SceneUV - Pivot , float2x2( UVRotator_cos , -UVRotator_sin , UVRotator_sin , UVRotator_cos))+ Pivot;
                }
/////////Fresnel :
                float3 fresnel = pow(1-max(0,(dot(viewDir,o.normal))),_Fresnel_Range);
                float3 fresnel_Color = fresnel * _Fresnel_Color *_Fresnel_Intensity;
/////////FinalColor :
                float4 MainTex = tex2D(_MainTex,TRANSFORM_TEX(SceneUV,_MainTex));
/////////Desaturate:
                if(_desaturate){
                    MainTex.rgb = dot(MainTex.rgb,float3(0.3,0.59,0.11));
                    if(_colorGradient){
                        float3 TexColor_Smoothstep = smoothstep(MainTex.rgb+0.4 , MainTex.rgb , _GradientValue);
                        float3 BrightColor = MainTex.rgb * TexColor_Smoothstep * _color1 ;
                        float3 DarkColor = MainTex.rgb * (1-TexColor_Smoothstep) * _color2;
                        MainTex.rgb = BrightColor+DarkColor;
                    }
                    else{
                       MainTex.rgb = MainTex.rgb*_desaturateColor.rgb;
                    }
                }
/////////FinalColor:
                float3 MainTex2 = MainTex.rgb*_MainColor.rgb*o.vertexColor.rgb+ fresnel_Color;
                if(_Fresnel){
                    return float4(MainTex2*FaceColor,MainTex.a*o.vertexColor.a);
                }
                else{
                     return float4(MainTex.rgb*_MainColor.rgb*o.vertexColor.rgb*FaceColor ,  MainTex.a*o.vertexColor.a);
                }
            }
            ENDCG
        }
    }
}
