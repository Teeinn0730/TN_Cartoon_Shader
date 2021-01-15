Shader "TN/PBR"{
	Properties{
		_BumpTex("Normal Map",2D) = "white"{}
		_MainTex("MainTex",2D) = "white" {}
		[HDR]_Color("MainColor",Color) = (1,1,1,1)
		_Metallic("Metallic",Range( 0 , 1 )) = 0
		_Gloss("Gloss", Range( 0 , 1) )= 0.8
	}

	SubShader{
		Tags{
			"RenderType" = "Opaque"
		}
		Pass{
			Tags{
			"LightMode" = "ForwardBase"
			}
			CGPROGRAM

			//pragma 語意定義
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing //  "GPU Instance"  semantics
			#pragma multi_compile_fwdbase_fullshadows // 與multi_compile_fwdadd類似，但是也包含了即時光影的功能。
			#pragma target 3.0 //OpenGlES 的版本號。//es3.0引入了新版本的GLSL shading language，所以编出来的东西肯定不一样。另外3.0和2.0不仅代表了api的变化，也代表了硬件能力的提升。别的不说，3.0完全支持了32位浮点数运算，光是这个就足够带来效果上的明显差异。还有，2.0要求depth buffer至少16bits，而3.0要求支持24bits和32bits。
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityStandardBRDF.cginc"
			//properties 參數建構
			uniform sampler2D _MainTex ; uniform float4 _MainTex_ST ;
			uniform sampler2D _BumpTex ; uniform float4 _BumpTex_ST ;
			float3 _Color; float _Metallic; float _Gloss;

			/* 支援GPU Instance的聲明公式:
			UNITY_INSTANCING_BUFFER_START(Props)  // 開始 (以下為GPU可代工的參數)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
				UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
				UNITY_DEFINE_INSTANCED_PROP(float, _Gloss)
			UNITY_INSTANCING_BUFFER_END(Props) // 結束
			*/

			//Struct 建構模型資訊
			struct VertexInput{
				// UNITY_VERTEX_INPUT_INSTANCE_ID // 只有当你需要在Fragment Shader中访问每个Instance独有的属性时才需要写这个宏。
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord0 : TEXCOORD0;
			};
			struct VertexOutput {
				// UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 bitangentDir : TEXCOORD4;
				LIGHTING_COORDS(5, 6)// 需要使用到LightMap的時候才需要指定TEX通道來存取。
				float3x3 tangentTrans : TEXCOORD7;
				// UNITY_FOG_COORDS(7) // 做FOG時需要的存取通道。
			};

			//把VertexOutput與VertexInput做資訊連結 (頂點著色器)
			VertexOutput vert (VertexInput i) {
				//UNITY_SETUP_INSTANCE_ID(v); //这个宏让Instance ID在Shader函数里能够被访问到
				//UNITY_TRANSFER_INSTANCE_ID(v, o); //把Instance ID从输入结构拷贝至输出结构中。 只有当你需要在Fragment Shader中访问每个Instance独有的属性时才需要写这个宏。
				VertexOutput o;
				o.pos = UnityObjectToClipPos(i.vertex); //為甚麼不用o.vertex的原因 : TRANSFER_VERTEX_TO_FRAGMENT会辅助我们进行阴影相关的计算，然后这里它在进行阴影坐标计算的时候，传入了一个a.pos，所以这也就是为什么我们的顶点输出结构里，必须将变量定义为pos的原因了
				o.uv0 = i.texcoord0;
				o.posWorld = mul( unity_ObjectToWorld , i.vertex );
				o.normalDir = UnityObjectToWorldNormal( i.normal );
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(i.tangent.xyz, 0)).xyz);
				o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir)*i.tangent.w); // bitangentDir 是Normal與Tangent的正交法線，所以使用cross。  另外v.tangent.w所存取的信息為-1到1之間。原理為Unity在OpenGl與DirectX的屏幕信息Y軸是相反的，OpenGL平台，U水平向右，V垂直向上即+y / DirectX平台，U水平向右，V垂直向下即-y 。Unity本身是走OpenGl的配置。
				/*// normalf, tangentf, binormalf分别是N T' B' 
				float dp = Dot(Cross(normalf, tangentf), binormalf);
				// 对比N×T'和B'的方向是否相同，如果不同，说明是DirectX平台
				if (dp > 0.0F) {outputTangent.w = 1.0F} ; else {outputTangent.w} = -1.0F;*/
				// UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_VERTEX_TO_FRAGMENT(o) //TRANSFER_VERTEX_TO_FRAGMENT，它定义在AutoLight.cginc文件中，它会与宏LIGHTING_COORDS协同工作，它会根据该pass处理的光源类型（ spot 或 point 或 directional ）来计算光源坐标的具体值，以及进行和 shadow 相关的计算等。
				o.tangentTrans = float3x3(o.tangentDir, o.bitangentDir, o.normalDir); // Normal的置換矩陣 1&2可對調，normalDir無法對調，原因為unity為左手坐標系，以normalmap來看的話rgb的b永遠是0.5，也是模型的基礎normal，而rg就是tangent與bitangent的意思，使用左手坐標，normal朝向自己旋轉的話，tan是上下或左右都ok。
				float3 lightColor = _LightColor0.rgb;
				return o;
			}

			//片元著色器 :                       //SV_Target或是COLOR都可以
			float4 frag(VertexOutput o) : COLOR{
				// UNITY_SETUP_INSTANCE_ID(o);
				float3x3 tangentTransform = float3x3(o.tangentDir, o.bitangentDir, o.normalDir);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				float3 bump_value = UnpackNormal(tex2D(_BumpTex, TRANSFORM_TEX(o.uv0, _BumpTex)));
				float3 bump_normalDir = normalize(mul(bump_value, tangentTransform));
				float3 viewReflectDir = reflect(-viewDir, o.normalDir); // 求反射角
				float3 lightDir = _WorldSpaceLightPos0, xyz;
				return float4 (lightDir,1);
				
			}

			
			ENDCG
		}
		
	}
}