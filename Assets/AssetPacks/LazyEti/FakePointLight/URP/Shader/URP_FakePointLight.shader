// Made with Amplify Shader Editor v1.9.3.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "LazyEti/URP/FakePointLight"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[Header(___Light Settings___)][SingleLineTexture][Space(10)]_GradientTexture("GradientTexture", 2D) = "white" {}
		[HDR]_LightTint("Light Tint", Color) = (1,1,1,1)
		[Space(5)]_LightSoftness("Light Softness", Range( 0 , 1)) = 0.5
		_LightPosterize("Light Posterize", Range( 1 , 128)) = 1
		[Space(5)]_ShadingBlend("Shading Blend", Range( 0 , 1)) = 0.5
		_ShadingSoftness("Shading Softness", Range( 0.01 , 1)) = 0.5
		[Space(25)][Toggle(___HALO____ON)] ___Halo___("___Halo___", Float) = 1
		[HDR]_HaloTint("Halo Tint", Color) = (1,1,1,1)
		_HaloSize("Halo Size", Range( 0 , 5)) = 1
		_HaloPosterize("Halo Posterize", Range( 1 , 128)) = 1
		[Space(25)][Toggle]DistanceFade("___Distance Fade___", Float) = 0
		[Tooltip(Starts fading away at this distance from the camera)]_FarFade("Far Fade", Range( 0 , 400)) = 200
		_FarTransition("Far Transition", Range( 1 , 100)) = 50
		_CloseFade("Close Fade", Range( 0 , 50)) = 0
		_CloseTransition("Close Transition", Range( 0 , 50)) = 0
		[Space(25)][Toggle(___FLICKERING____ON)] ___Flickering___("___Flickering___", Float) = 0
		_FlickerIntensity("Flicker Intensity", Range( 0.1 , 1)) = 0.5
		_FlickerSpeed("Flicker Speed", Range( 0.01 , 5)) = 1
		_FlickerSoftness("Flicker Softness", Range( 0 , 1)) = 0.5
		_SizeFlickering("Size Flickering", Range( 0 , 0.5)) = 0.1
		[HideInInspector]_randomOffset("randomOffset", Range( 0 , 1)) = 0
		[Space(25)][Toggle(___NOISE____ON)] ___Noise___("___Noise___", Float) = 0
		[SingleLineTexture]_NoiseTexture("Noise Texture", 2D) = "black" {}
		_Noisiness("Noisiness", Range( 0 , 2)) = 0
		_NoiseScale("Noise Scale", Range( 0.1 , 2)) = 1
		_NoiseMovement("Noise Movement", Range( 0 , 1)) = 0
		[Space(20)][Header(___Extra Settings___)][Space(10)][Toggle(_PARTICLEMODE_ON)] _ParticleMode("Particle Mode", Float) = 0
		[Space(15)][Toggle]DayAlpha("Day Alpha", Float) = 0
		[Space (15)][Toggle(__HEAVYSHADOWS_ON)] __HEAVYShadows("Shadows (HEAVY)", Float) = 0
		_StepSpacing("Steps Spacing", Range( 1 , 5)) = 3


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Overlay" "Queue"="Overlay" "UniversalMaterialType"="Unlit" }

		Cull Front
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha One, SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			ZTest Always
			Offset 0,0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_SRP_VERSION 140010
			#define REQUIRE_DEPTH_TEXTURE 1
			#define ASE_USING_SAMPLING_MACROS 1


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local ___HALO____ON
			#pragma shader_feature_local _PARTICLEMODE_ON
			#pragma shader_feature_local ___FLICKERING____ON
			#pragma shader_feature_local ___NOISE____ON
			#pragma shader_feature_local __HEAVYSHADOWS_ON


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _HaloTint;
			float4 _LightTint;
			float _HaloSize;
			float _FarTransition;
			float _FarFade;
			float DistanceFade;
			float DayAlpha;
			float _StepSpacing;
			float _ShadingSoftness;
			float _ShadingBlend;
			float _LightPosterize;
			float _NoiseScale;
			float _NoiseMovement;
			float _Noisiness;
			float _LightSoftness;
			float _HaloPosterize;
			float _SizeFlickering;
			float _FlickerIntensity;
			float _FlickerSoftness;
			float _randomOffset;
			float _FlickerSpeed;
			float _CloseFade;
			float _CloseTransition;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			TEXTURE2D(_GradientTexture);
			SAMPLER(sampler_GradientTexture);
			TEXTURE2D(_NoiseTexture);
			TEXTURE2D(_CameraNormalsTexture);
			SAMPLER(sampler_CameraNormalsTexture);
			SAMPLER(sampler_NoiseTexture);


			float noise58_g652( float x )
			{
				float n = sin (2 * x) + sin(3.14159265 * x);
				return n;
			}
			
			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDirURP75_g618( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION == 70600 || ASE_SRP_VERSION == 70700 || ASE_SRP_VERSION == 70701 || ASE_SRP_VERSION >= 80301
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			
			float ExperimentalScreenShadows( TEXTURE2D(_CameraDepthTexture), SamplerState _SS, float3 _LightPos, float3 _ScreenPos, float _Spacing )
			{
				 float3 _screenPos = _ScreenPos;
				    
					float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,_SS,_screenPos.xy).r;
				    depth = 1/(_ZBufferParams.z * depth + _ZBufferParams.w);
				    _screenPos.z = depth ;
				    float3 ray = ( _LightPos )/ (400 / _Spacing);
				    half dist = distance(_LightPos.xy,.5f );
				     if (depth>_LightPos.z && dist <= 5)
				     {
				         for (int i = 0;i < 20 ;i++)
				         {                    
				            float3 _newPos = _screenPos + (ray * i);
					        float _d = SAMPLE_TEXTURE2D(_CameraDepthTexture,_SS,_newPos.xy ).r;
					        _d = 1/(_ZBufferParams.z * _d + _ZBufferParams.w);
					        float dif =  _newPos.z - _d;
				            if ( dif < 20 && dif > 0)  return 0;
				         }
				     }
				    return 1;
			}
			
			half3 HSVToRGB( half3 c )
			{
				half4 K = half4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				half3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord5 = screenPos;
				float3 vertexToFrag7_g663 = _MainLightPosition.xyz;
				o.ase_texcoord6.xyz = vertexToFrag7_g663;
				
				o.ase_texcoord3.xyz = v.ase_texcoord1.xyz;
				o.ase_texcoord4 = v.ase_texcoord;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				o.ase_texcoord6.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				#ifdef _PARTICLEMODE_ON
				float staticSwitch726 = ( _HaloSize * ( IN.ase_texcoord3.xyz.x * 0.1 ) );
				#else
				float staticSwitch726 = _HaloSize;
				#endif
				float mulTime17_g652 = _TimeParameters.x * ( _FlickerSpeed * 4 );
				#ifdef _PARTICLEMODE_ON
				float staticSwitch1913 = IN.ase_texcoord4.w;
				#else
				float staticSwitch1913 = _randomOffset;
				#endif
				float x58_g652 = ( mulTime17_g652 + ( staticSwitch1913 * PI ) );
				float localnoise58_g652 = noise58_g652( x58_g652 );
				float temp_output_44_0_g652 = ( ( 1.0 - _FlickerSoftness ) * 0.5 );
				#ifdef ___FLICKERING____ON
				float staticSwitch53_g652 = saturate( (( 1.0 - _FlickerIntensity ) + ((0.0 + (localnoise58_g652 - -2.0) * (1.0 - 0.0) / (2.0 - -2.0)) - ( 1.0 - temp_output_44_0_g652 )) * (1.0 - ( 1.0 - _FlickerIntensity )) / (temp_output_44_0_g652 - ( 1.0 - temp_output_44_0_g652 ))) );
				#else
				float staticSwitch53_g652 = 1.0;
				#endif
				float FlickerAlpha416 = staticSwitch53_g652;
				float FlickerSize477 = (( 1.0 - _SizeFlickering ) + (FlickerAlpha416 - 0.0) * (1.0 - ( 1.0 - _SizeFlickering )) / (1.0 - 0.0));
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float4 transform620 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch730 = float4( IN.ase_texcoord4.xyz , 0.0 );
				#else
				float4 staticSwitch730 = transform620;
				#endif
				float dotResult962 = dot( float4( ase_worldViewDir , 0.0 ) , ( float4( _WorldSpaceCameraPos , 0.0 ) - staticSwitch730 ) );
				float4 objectToClip584 = TransformObjectToHClip(float3( 0,0,0 ));
				float3 objectToClip584NDC = objectToClip584.xyz/objectToClip584.w;
				float4 worldToClip716 = TransformWorldToHClip(IN.ase_texcoord4.xyz);
				float3 worldToClip716NDC = worldToClip716.xyz/worldToClip716.w;
				#ifdef _PARTICLEMODE_ON
				float3 staticSwitch712 = worldToClip716NDC;
				#else
				float3 staticSwitch712 = objectToClip584NDC;
				#endif
				float4 worldToClip583 = TransformWorldToHClip(WorldPosition);
				float3 worldToClip583NDC = worldToClip583.xyz/worldToClip583.w;
				float2 appendResult1075 = (float2(( _ScreenParams.x / _ScreenParams.y ) , 1.0));
				float smoothstepResult593 = smoothstep( 0.0 , ( staticSwitch726 * FlickerSize477 ) , ( dotResult962 > 0.0 ? length( ( ( (( staticSwitch712 - worldToClip583NDC )).xy * appendResult1075 ) * ( unity_OrthoParams.w <= 0.0 ? ( distance( _WorldSpaceCameraPos , staticSwitch730.xyz ) / -UNITY_MATRIX_P[ 1 ][ 1 ] ) : unity_OrthoParams.x ) ) ) : 20.0 ));
				float HaloMask616 = ( 1.0 - smoothstepResult593 );
				float temp_output_5_0_g665 = ( 256.0 / _HaloPosterize );
				float HaloPosterized651 = ( HaloMask616 * saturate( ( floor( ( HaloMask616 * temp_output_5_0_g665 ) ) / temp_output_5_0_g665 ) ) );
				float2 temp_cast_4 = (( 1.0 - HaloPosterized651 )).xx;
				float4 temp_output_608_0 = ( HaloPosterized651 * SAMPLE_TEXTURE2D( _GradientTexture, sampler_GradientTexture, temp_cast_4 ) * _HaloTint * IN.ase_color );
				float2 temp_cast_5 = (( 1.0 - HaloPosterized651 )).xx;
				float4 screenPos = IN.ase_texcoord5;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 temp_output_77_0_g618 = ase_screenPosNorm;
				float2 UV22_g619 = temp_output_77_0_g618.xy;
				float2 localUnStereo22_g619 = UnStereo( UV22_g619 );
				float2 break64_g618 = localUnStereo22_g619;
				float clampDepth69_g618 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( temp_output_77_0_g618.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g618 = ( 1.0 - clampDepth69_g618 );
				#else
				float staticSwitch38_g618 = clampDepth69_g618;
				#endif
				float3 appendResult39_g618 = (float3(break64_g618.x , break64_g618.y , staticSwitch38_g618));
				float4 appendResult42_g618 = (float4((appendResult39_g618*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g618 = mul( unity_CameraInvProjection, appendResult42_g618 );
				float3 temp_output_46_0_g618 = ( (temp_output_43_0_g618).xyz / (temp_output_43_0_g618).w );
				float3 In75_g618 = temp_output_46_0_g618;
				float3 localInvertDepthDirURP75_g618 = InvertDepthDirURP75_g618( In75_g618 );
				float4 appendResult49_g618 = (float4(localInvertDepthDirURP75_g618 , 1.0));
				float4 ReconstructedPos539 = mul( unity_CameraToWorld, appendResult49_g618 );
				float4 transform678 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch721 = float4( IN.ase_texcoord4.xyz , 0.0 );
				#else
				float4 staticSwitch721 = transform678;
				#endif
				float HaloPenetrationMask683 = saturate( ( distance( ReconstructedPos539 , float4( _WorldSpaceCameraPos , 0.0 ) ) - distance( float4( _WorldSpaceCameraPos , 0.0 ) , staticSwitch721 ) ) );
				#ifdef ___HALO____ON
				float4 staticSwitch1971 = ( temp_output_608_0 * ( (temp_output_608_0).a * HaloMask616 * HaloPenetrationMask683 ) );
				#else
				float4 staticSwitch1971 = float4( 0,0,0,0 );
				#endif
				float temp_output_767_0 = ( ( 1.0 - _LightSoftness ) + -0.5 );
				float3 worldToObj263 = mul( GetWorldToObjectMatrix(), float4( ReconstructedPos539.xyz, 1 ) ).xyz;
				float3 worldToObj137 = mul( GetWorldToObjectMatrix(), float4( ( ReconstructedPos539 - float4( IN.ase_texcoord4.xyz , 0.0 ) ).xyz, 1 ) ).xyz;
				float3 ParticlePos653 = worldToObj137;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( GetWorldToObjectMatrix()[ 0 ].xyz ), length( GetWorldToObjectMatrix()[ 1 ].xyz ), length( GetWorldToObjectMatrix()[ 2 ].xyz ) ) );
				#ifdef _PARTICLEMODE_ON
				float3 staticSwitch255 = ( ParticlePos653 / ( IN.ase_texcoord3.xyz + ase_parentObjectScale ) );
				#else
				float3 staticSwitch255 = worldToObj263;
				#endif
				float temp_output_55_0 = length( ( staticSwitch255 / ( 0.45 * FlickerSize477 ) ) );
				float mulTime41_g667 = _TimeParameters.x * ( _NoiseMovement * 0.2 );
				float3 objToWorld506 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_8_0_g667 = ( ( ReconstructedPos539 - float4( objToWorld506 , 0.0 ) ).xyz * ( _NoiseScale * 0.1 ) );
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float4 tex2DNode16 = SAMPLE_TEXTURE2D( _CameraNormalsTexture, sampler_CameraNormalsTexture, ase_grabScreenPosNorm.xy );
				float4 worldNormals1927 = tex2DNode16;
				float3 temp_output_24_0_g667 = abs( round( worldNormals1927.rgb ) );
				float temp_output_22_0_g667 = (temp_output_24_0_g667).x;
				float2 lerpResult19_g667 = lerp( (( ( float3(0.78,0.9,-0.72) * mulTime41_g667 ) + temp_output_8_0_g667 )).xz , (( ( float3(0.78,0.9,-0.72) * mulTime41_g667 ) + temp_output_8_0_g667 )).yz , temp_output_22_0_g667);
				float temp_output_23_0_g667 = (temp_output_24_0_g667).z;
				float2 lerpResult20_g667 = lerp( lerpResult19_g667 , (( ( float3(0.78,0.9,-0.72) * mulTime41_g667 ) + temp_output_8_0_g667 )).xy , temp_output_23_0_g667);
				float2 lerpResult46_g667 = lerp( (( ( mulTime41_g667 * float3(-0.86,-0.6,0.82) ) + temp_output_8_0_g667 )).xz , (( ( mulTime41_g667 * float3(-0.86,-0.6,0.82) ) + temp_output_8_0_g667 )).yz , temp_output_22_0_g667);
				float2 lerpResult47_g667 = lerp( lerpResult46_g667 , (( ( mulTime41_g667 * float3(-0.86,-0.6,0.82) ) + temp_output_8_0_g667 )).xy , temp_output_23_0_g667);
				#ifdef ___NOISE____ON
				float staticSwitch853 = saturate( ( _Noisiness * SAMPLE_TEXTURE2D( _NoiseTexture, sampler_NoiseTexture, lerpResult20_g667 ).r * SAMPLE_TEXTURE2D( _NoiseTexture, sampler_NoiseTexture, lerpResult47_g667 ).r ) );
				#else
				float staticSwitch853 = 0.0;
				#endif
				float temp_output_514_0 = ( temp_output_55_0 * ( temp_output_55_0 + staticSwitch853 ) );
				float smoothstepResult745 = smoothstep( temp_output_767_0 , ( 1.0 - temp_output_767_0 ) , temp_output_514_0);
				float temp_output_5_0_g620 = ( 256.0 / _LightPosterize );
				float GradientMask555 = ( ( 1.0 - smoothstepResult745 ) * saturate( ( floor( ( ( 1.0 - smoothstepResult745 ) * temp_output_5_0_g620 ) ) / temp_output_5_0_g620 ) ) );
				float2 temp_cast_17 = (( 1.0 - GradientMask555 )).xx;
				float4 temp_output_200_0 = ( GradientMask555 * SAMPLE_TEXTURE2D( _GradientTexture, sampler_GradientTexture, temp_cast_17 ) * _LightTint * IN.ase_color );
				float2 temp_cast_18 = (( 1.0 - GradientMask555 )).xx;
				float surfaceMask487 = step( temp_output_514_0 , 0.999 );
				float3 objToWorld437 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch566 = float4( ( 1.0 - ParticlePos653 ) , 0.0 );
				#else
				float4 staticSwitch566 = ( float4( objToWorld437 , 0.0 ) - ReconstructedPos539 );
				#endif
				float dotResult436 = dot( staticSwitch566 , tex2DNode16 );
				TEXTURE2D(_CameraDepthTexture6_g671) = _CameraDepthTexture;
				SamplerState _SS6_g671 = sampler_CameraDepthTexture;
				float4 transform1852 = mul(GetWorldToObjectMatrix(),float4( IN.ase_texcoord4.xyz , 0.0 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch1850 = transform1852;
				#else
				float4 staticSwitch1850 = float4( 0,0,0,0 );
				#endif
				float3 temp_output_85_0_g671 = staticSwitch1850.xyz;
				float3 objectToClip91_g671 = TransformObjectToHClip(temp_output_85_0_g671).xyz;
				float4 worldToClip165_g671 = TransformWorldToHClip(WorldPosition);
				float3 worldToClip165_g671NDC = worldToClip165_g671.xyz/worldToClip165_g671.w;
				float2 appendResult161_g671 = (float2(( _ScreenParams.x / _ScreenParams.y ) , 1.0));
				float3 break29_g671 = ( ( objectToClip91_g671 - worldToClip165_g671NDC ) * float3( appendResult161_g671 ,  0.0 ) );
				float2 appendResult14_g671 = (float2(break29_g671.x , ( -break29_g671.y * 2 )));
				float temp_output_13_0_g671 = -break29_g671.y;
				float3 appendResult44_g671 = (float3(appendResult14_g671 , ( temp_output_13_0_g671 > 0.0 ? -0.001 : temp_output_13_0_g671 )));
				float4 objectToClip167_g671 = TransformObjectToHClip(temp_output_85_0_g671);
				float3 objectToClip167_g671NDC = objectToClip167_g671.xyz/objectToClip167_g671.w;
				float3 break206_g671 = ( float3( appendResult161_g671 ,  0.0 ) * ( objectToClip167_g671NDC - worldToClip165_g671NDC ) );
				float2 appendResult207_g671 = (float2(break206_g671.x , ( -break206_g671.y * 2 )));
				float eyeDepth210_g671 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float3 appendResult46_g671 = (float3(appendResult207_g671 , ( 5.0 * saturate( ( break206_g671.y + 0.3 ) ) * ( saturate( ( 1.0 - abs( ase_worldViewDir.y ) ) ) + 0.5 ) * ( 1.0 - eyeDepth210_g671 ) )));
				float3 temp_output_28_0_g671 = ( unity_OrthoParams.w > 0.0 ? appendResult44_g671 : appendResult46_g671 );
				float3 _LightPos6_g671 = temp_output_28_0_g671;
				float3 _ScreenPos6_g671 = ase_screenPosNorm.xyz;
				float _Spacing6_g671 = _StepSpacing;
				float localExperimentalScreenShadows6_g671 = ExperimentalScreenShadows( _CameraDepthTexture6_g671 , _SS6_g671 , _LightPos6_g671 , _ScreenPos6_g671 , _Spacing6_g671 );
				#ifdef __HEAVYSHADOWS_ON
				float staticSwitch7_g671 = localExperimentalScreenShadows6_g671;
				#else
				float staticSwitch7_g671 = 1.0;
				#endif
				float ScreenSpaceShadows1881 = staticSwitch7_g671;
				float ifLocalVar862 = 0;
				if( 1.0 <= _ShadingBlend )
				ifLocalVar862 = 1.0;
				else
				ifLocalVar862 = saturate( ( ( pow( saturate( dotResult436 ) , _ShadingSoftness ) * ScreenSpaceShadows1881 ) + _ShadingBlend ) );
				float NormalsMasking552 = ifLocalVar862;
				float3 vertexToFrag7_g663 = IN.ase_texcoord6.xyz;
				float dotResult3_g663 = dot( -vertexToFrag7_g663 , float3( 0,1,0 ) );
				half3 hsvTorgb47_g652 = HSVToRGB( half3(radians( staticSwitch53_g652 ),1.0,1.0) );
				float3 lerpResult51_g652 = lerp( hsvTorgb47_g652 , float3( 1,1,1 ) , staticSwitch53_g652);
				float3 FlickerHue1892 = lerpResult51_g652;
				float4 transform1952 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch1917 = float4( IN.ase_texcoord4.xyz , 0.0 );
				#else
				float4 staticSwitch1917 = transform1952;
				#endif
				float3 _Vector0 = float3(1,0,1);
				float Dist41_g664 = distance( ( staticSwitch1917.xyz * _Vector0 ) , ( _Vector0 * _WorldSpaceCameraPos ) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( ( staticSwitch1971 + ( temp_output_200_0 * ( (temp_output_200_0).a * surfaceMask487 * NormalsMasking552 * 0.1 ) ) ) * (( DayAlpha )?( saturate( ( dotResult3_g663 * 4.0 ) ) ):( 1.0 )) * float4( ( FlickerAlpha416 * FlickerHue1892 ) , 0.0 ) * (( DistanceFade )?( ( saturate( ( 1.0 - ( ( Dist41_g664 - _FarFade ) / _FarTransition ) ) ) * saturate( ( ( Dist41_g664 - _CloseFade ) / _CloseTransition ) ) ) ):( 1.0 )) ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.positionCS, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			

			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140010
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _HaloTint;
			float4 _LightTint;
			float _HaloSize;
			float _FarTransition;
			float _FarFade;
			float DistanceFade;
			float DayAlpha;
			float _StepSpacing;
			float _ShadingSoftness;
			float _ShadingBlend;
			float _LightPosterize;
			float _NoiseScale;
			float _NoiseMovement;
			float _Noisiness;
			float _LightSoftness;
			float _HaloPosterize;
			float _SizeFlickering;
			float _FlickerIntensity;
			float _FlickerSoftness;
			float _randomOffset;
			float _FlickerSpeed;
			float _CloseFade;
			float _CloseTransition;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				o.positionCS = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _HaloTint;
			float4 _LightTint;
			float _HaloSize;
			float _FarTransition;
			float _FarFade;
			float DistanceFade;
			float DayAlpha;
			float _StepSpacing;
			float _ShadingSoftness;
			float _ShadingBlend;
			float _LightPosterize;
			float _NoiseScale;
			float _NoiseMovement;
			float _Noisiness;
			float _LightSoftness;
			float _HaloPosterize;
			float _SizeFlickering;
			float _FlickerIntensity;
			float _FlickerSoftness;
			float _randomOffset;
			float _FlickerSpeed;
			float _CloseFade;
			float _CloseTransition;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 140010
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _HaloTint;
			float4 _LightTint;
			float _HaloSize;
			float _FarTransition;
			float _FarFade;
			float DistanceFade;
			float DayAlpha;
			float _StepSpacing;
			float _ShadingSoftness;
			float _ShadingBlend;
			float _LightPosterize;
			float _NoiseScale;
			float _NoiseMovement;
			float _Noisiness;
			float _LightSoftness;
			float _HaloPosterize;
			float _SizeFlickering;
			float _FlickerIntensity;
			float _FlickerSoftness;
			float _randomOffset;
			float _FlickerSpeed;
			float _CloseFade;
			float _CloseTransition;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			

			#define _SURFACE_TYPE_TRANSPARENT 1
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140010
			#define ASE_USING_SAMPLING_MACROS 1


			

			#pragma vertex vert
			#pragma fragment frag

        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _HaloTint;
			float4 _LightTint;
			float _HaloSize;
			float _FarTransition;
			float _FarFade;
			float DistanceFade;
			float DayAlpha;
			float _StepSpacing;
			float _ShadingSoftness;
			float _ShadingBlend;
			float _LightPosterize;
			float _NoiseScale;
			float _NoiseMovement;
			float _Noisiness;
			float _LightSoftness;
			float _HaloPosterize;
			float _SizeFlickering;
			float _FlickerIntensity;
			float _FlickerSoftness;
			float _randomOffset;
			float _FlickerSpeed;
			float _CloseFade;
			float _CloseTransition;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = v.normalOS;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

				o.positionCS = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag( VertexOutput IN
				, out half4 outNormalWS : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
				 )
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float3 normalWS = normalize(IN.normalWS);
					float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					float3 normalWS = IN.normalWS;
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback "Hidden/InternalErrorShader"
}
/*ASEBEGIN
Version=19303
Node;AmplifyShaderEditor.CommentaryNode;442;-4212.421,-646.5759;Inherit;False;2475.9;453.022;Be sure to have a renderer feature that writes to _CameraNormalsTexture for this to work;21;552;862;863;551;562;471;1882;566;1927;549;438;550;1289;437;565;12;655;16;572;436;563;Normal Direction Masking;0.6086246,0.5235849,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;753;-148.7889,-663.3845;Inherit;False;927.7325;257.7322;;5;651;752;754;643;642;HaloPosterize;0.4575472,0.7270408,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;689;-1711,-96;Inherit;False;1448.234;521.4906;;15;2008;2004;2009;2010;616;1294;656;726;737;738;648;722;594;593;2014;Halo Masking;1,0.6179246,0.9947789,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;684;-176,176;Inherit;False;1638.72;440.3387;;12;141;1976;553;140;201;557;143;202;488;607;707;200;Light Radius Mix;1,0.4198113,0.7623972,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;682;-1584,512;Inherit;False;1296.726;444.869;;10;678;721;720;667;636;635;672;637;675;683;Halo Penetration Fade;0.3773585,0.3773585,0.3773585,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;666;-176,-336;Inherit;False;1856.204;445.3508;;12;652;669;481;649;650;1971;603;686;685;617;687;608;Halo Mix;0,1,0.4267647,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;611;-4512,-128;Inherit;False;2766.183;507.3311;;23;1300;962;961;621;964;2003;1075;589;587;620;730;731;586;623;591;1074;583;582;716;717;585;712;584;Halo Position;0.4446237,0.4431373,0.8588235,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;513;-1582.23,-543.8651;Inherit;False;1290.465;351.589;;5;853;1929;542;506;505;Noise;1,0.6084906,0.6084906,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;510;5.103966,-1080.573;Inherit;False;1051.51;320.2816;;9;771;745;765;66;769;767;487;485;514;Light Mask Hardness;1,0.8561655,0.3632075,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;500;872.3984,-667.6311;Inherit;False;989.2166;262.1571;;5;555;770;640;492;775;Light Posterize;0.5707547,1,0.9954711,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;484;-4352.669,-1078.827;Inherit;False;1617.816;369.3069;;9;742;1914;1913;466;1892;463;467;477;416;Radius;0.5613208,0.8882713,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;480;-1684.524,-1077.199;Inherit;False;1398.708;444.8386;;15;654;262;259;261;260;478;680;420;55;264;255;983;539;263;711;World SphericalMask;0.9034846,0.5330188,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;476;-2694.234,-1059.704;Inherit;False;909.0739;351.2957;;7;653;137;252;541;709;254;486;Particle transform;0.5424528,1,0.9184569,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1356;-3168,448;Inherit;False;1480.975;345.7733;Experimental screen shadows;4;1850;1852;1851;1881;;1,0.0518868,0.0518868,1;0;0
Node;AmplifyShaderEditor.StickyNoteNode;486;-2248.26,-1019.167;Inherit;False;389.5999;134.3;Particle Custom Vertex stream setup !!;;1,0.9012449,0.3254717,1;1. Center = TexCoord0.xyz  (Particle Position)$$2. StableRandom.x TexCoord0.w (random flicker)$$3. Size.xyz = TexCoord1.xyz (Particle Size);0;0
Node;AmplifyShaderEditor.StickyNoteNode;709;-2676.301,-941.0137;Inherit;False;215;182;Center (Texcoord0.xyz);;1,1,1,1;;0;0
Node;AmplifyShaderEditor.StickyNoteNode;711;-1648.394,-848.5927;Inherit;False;208;181;Size.xyz (Texcoord1.xyz);;1,1,1,1;;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;683;-528,640;Inherit;False;HaloPenetrationMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;653;-2042.199,-865.5414;Inherit;False;ParticlePos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;514;28.78838,-1027.972;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;485;190.3592,-975.1706;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.999;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;771;907.8933,-1034.466;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;745;717.0555,-1033.319;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.04;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;765;581.213,-870.0805;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;767;452.1794,-867.0805;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;769;316.1792,-867.0805;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;509;-165.7451,-960.9916;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;675;-832,640;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;637;-992,576;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;672;-672,640;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;635;-1232,576;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;487;332.8367,-975.9942;Inherit;False;surfaceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;754;-48.70786,-603.0811;Inherit;False;616;HaloMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;752;393.7577,-601.4481;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;770;1489.614,-606.1196;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;252;-2665.634,-904.9504;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;541;-2650.645,-1016.229;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;563;-3112.25,-571.3048;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;436;-3232.837,-572.2302;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;572;-3746.346,-471.3954;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;16;-3584.257,-419.7703;Inherit;True;Global;_CameraNormalsTexture;_CameraNormalsTexture;0;0;Create;True;0;0;0;False;0;False;-1;None;;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;655;-3919.877,-471.9501;Inherit;False;653;ParticlePos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GrabScreenPosition;12;-3788.667,-395.2679;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;565;-4155.978,-424.8857;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TransformPositionNode;437;-4153.787,-570.2493;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1289;-2682.813,-571.5327;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;550;-2957.579,-571.1129;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;438;-3918.168,-570.5811;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StaticSwitch;1850;-2688,544;Inherit;False;Property;_ParticleMesh6;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1881;-2016,544;Inherit;False;ScreenSpaceShadows;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;566;-3599.415,-571.9556;Inherit;False;Property;_ParticleMesh1;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;254;-2435.062,-972.353;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TransformPositionNode;137;-2270.084,-866.4276;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;263;-1147.08,-1027.044;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;539;-1377.606,-1026.894;Inherit;False;ReconstructedPos;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;983;-1607.087,-1026.48;Inherit;False;WPos From Depth;-1;;618;e7094bcbcc80eb140b2a3dbe6a861de8;0;1;77;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;420;-715.6204,-896.0656;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;680;-888.8984,-914.6563;Inherit;False;Constant;_s;s;20;0;Create;True;0;0;0;False;0;False;0.45;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;478;-890.4405,-843.5002;Inherit;False;477;FlickerSize;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;260;-1640.797,-813.7918;Inherit;False;1;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;261;-1211.053,-813.9485;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectScaleNode;259;-1407.874,-789.6442;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;262;-1048.119,-862.232;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;654;-1271.828,-883.7238;Inherit;False;653;ParticlePos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;1882;-2959.942,-472.5295;Inherit;False;1881;ScreenSpaceShadows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;562;-2432.185,-572.0081;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;551;-2318.992,-571.2352;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;863;-2312.642,-398.9397;Inherit;False;Constant;_Float0;Float 0;23;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;416;-3418.404,-985.4626;Inherit;False;FlickerAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;477;-2978.031,-986.1696;Inherit;False;FlickerSize;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;467;-3314.451,-838.9294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1892;-3420.24,-915.9872;Inherit;False;FlickerHue;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;466;-3164.095,-985.5343;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;1913;-3989.652,-912.697;Inherit;False;Property;_ParticleMesh7;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;742;-4257.768,-911.8267;Inherit;False;0;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;505;-1255.966,-443.2927;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TransformPositionNode;506;-1499.657,-371.927;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;542;-1503.032,-443.7211;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;1929;-1089.745,-372.812;Inherit;False;1927;worldNormals;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;463;-3587.511,-839.5694;Inherit;False;Property;_SizeFlickering;Size Flickering;23;0;Create;True;0;0;0;False;0;False;0.1;0;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1914;-4315.652,-979.697;Inherit;False;Property;_randomOffset;randomOffset;24;1;[HideInInspector];Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;555;1637.652,-606.1025;Inherit;False;GradientMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;775;1095.297,-605.5555;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;640;1232.082,-544.3308;Inherit;False;SimplePosterize;-1;;620;163fbd1f7d6893e4ead4288913aedc26;0;2;9;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;651;559.4694,-601.5095;Inherit;False;HaloPosterized;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;853;-549.4682,-492.0063;Inherit;False;Property;___Noise___;___Noise___;25;0;Create;True;0;0;0;False;1;Space(25);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;264;-558.9969,-1026.174;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LengthOpNode;55;-441.5539,-1026.4;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;255;-911.3533,-1026.605;Inherit;False;Property;_ParticleMode;Particle Mode;31;0;Create;True;0;0;0;False;3;Space(20);Header(___Extra Settings___);Space(10);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;1983;-3716.636,-985.2504;Inherit;False;FlickerFunction;18;;652;f6225b1ef66c663478bc4f0259ec00df;0;4;9;FLOAT;0;False;8;FLOAT;0;False;21;FLOAT;0;False;29;FLOAT;0;False;2;FLOAT;0;FLOAT3;45
Node;AmplifyShaderEditor.RangedFloatNode;492;945.3987,-519.6932;Inherit;False;Property;_LightPosterize;Light Posterize;4;0;Create;True;0;0;0;False;0;False;1;1;1;128;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;42.73463,-868.8215;Inherit;False;Property;_LightSoftness;Light Softness;3;0;Create;True;0;0;0;False;1;Space(5);False;0.5;10;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;636;-1264,640;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DistanceOpNode;667;-992,688;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;720;-1536,800;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;721;-1264,784;Inherit;False;Property;_ParticleMesh3;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;678;-1520,640;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldToObjectTransfNode;1852;-2864,576;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1851;-3104,576;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;584;-4288,-48;Inherit;False;Object;Clip;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StaticSwitch;712;-4064,-48;Inherit;False;Property;_ParticleMesh2;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;585;-3632,-48;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;608;736,-272;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;687;1264,-272;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;617;896,-128;Inherit;False;616;HaloMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;686;896,-208;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;200;800,240;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;707;80,320;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;607;224,304;Inherit;True;Property;_ColorGradient1;ColorGradient;1;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;481;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;488;976,368;Inherit;False;487;surfaceMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;202;944,304;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;143;1168,304;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;557;-128,240;Inherit;False;555;GradientMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;685;864,-64;Inherit;False;683;HaloPenetrationMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;603;1120,-208;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;201;704,432;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;140;512,352;Inherit;False;Property;_LightTint;Light Tint;2;1;[HDR];Create;True;1;___Light Settings___;0;0;False;0;False;1,1,1,1;0.6320754,0.275881,0,0.5333334;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;553;944,432;Inherit;False;552;NormalsMasking;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;1312,240;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;600;1600,208;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;657;2176,208;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;1384;1792,304;Inherit;False;416;FlickerAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1977;1984,272;Inherit;False;DayAlpha;32;;663;bc1f8ebe2e26696419e0099f8a3e27dc;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1901;1984,336;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;1897;1792,368;Inherit;False;1892;FlickerHue;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;1971;1424,-288;Inherit;False;Property;___Halo___;___Halo___;7;0;Create;True;0;0;0;False;1;Space(25);False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1927;-3245.483,-345.0956;Inherit;False;worldNormals;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;1988;1920,448;Inherit;False;AdvancedCameraFade;12;;664;e6e830f789d28b746963801d61c2a1ec;0;6;40;FLOAT;0;False;46;FLOAT;0;False;47;FLOAT;0;False;48;FLOAT;0;False;17;FLOAT3;0,0,0;False;20;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;1952;1520,464;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1916;1488,624;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;642;144,-544;Inherit;False;SimplePosterize;-1;;665;163fbd1f7d6893e4ead4288913aedc26;0;2;9;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;643;-128,-512;Inherit;False;Property;_HaloPosterize;Halo Posterize;11;0;Create;True;0;0;0;False;0;False;1;0;1;128;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;649;464,-128;Inherit;False;Property;_HaloTint;Halo Tint;9;1;[HDR];Create;True;1;___Halo___;0;0;False;0;False;1,1,1,1;0.6320754,0.275881,0,0.5333334;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;650;672,-80;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;669;48,-208;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;652;-160,-272;Inherit;False;651;HaloPosterized;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;481;192,-224;Inherit;True;Property;_GradientTexture;GradientTexture;1;2;[Header];[SingleLineTexture];Create;True;1;___Light Settings___;0;0;False;1;Space(10);False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;717;-4496,96;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;716;-4288,96;Inherit;False;World;Clip;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;582;-4064,64;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;583;-3888,64;Inherit;False;World;Clip;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ComponentMaskNode;1074;-3472,-48;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;623;-2208,-48;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;586;-2064,-48;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;731;-2912,112;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;730;-2704,48;Inherit;False;Property;_ParticleMesh5;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;620;-3072,48;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenParams;587;-3664,48;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;2003;-2464,48;Inherit;False;PerspectiveScalingFunction;-1;;666;ae280d8cb1effe748857bbeed4caf0b3;0;1;9;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;964;-2416,176;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;621;-2672,176;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;961;-2176,80;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;962;-2000,144;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;1300;-1888,-48;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;20;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;589;-3488,80;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;1075;-3376,80;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;591;-3248,-48;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;593;-752,-48;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;1294;-592,-48;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;616;-464,-48;Inherit;False;HaloMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;648;-896,16;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;594;-1632,16;Inherit;False;Property;_HaloSize;Halo Size;10;1;[Header];Create;True;0;0;0;False;0;False;1;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;737;-1328,80;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;726;-1168,16;Inherit;False;Property;_ParticleMesh4;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;722;-1680,96;Inherit;False;1;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleNode;738;-1472,128;Inherit;False;0.1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;656;-1104,112;Inherit;False;477;FlickerSize;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectScaleNode;2004;-1472,208;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMinOpNode;2010;-1184,256;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;2008;-1072,256;Inherit;False;0.1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;2014;-928,256;Inherit;False;Property;_ObjectScale;ObjectScale;8;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;2009;-1296,224;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;2015;-866.6163,-468.5807;Inherit;False;3DNoiseMap;26;;667;2fca756491ec7bf4e9c71d18280c45cc;0;5;56;FLOAT;0;False;1;FLOAT3;0,0,0;False;21;FLOAT3;0,0,0;False;7;FLOAT;0;False;54;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ConditionalIfNode;862;-2137.617,-486.8447;Inherit;False;False;5;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;471;-2688,-464;Inherit;False;Property;_ShadingBlend;Shading Blend;5;0;Create;True;0;0;0;False;1;Space(5);False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;549;-3257.876,-468.7709;Inherit;False;Property;_ShadingSoftness;Shading Softness;6;0;Create;True;0;0;0;False;0;False;0.5;1;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;552;-1958.558,-486.1915;Inherit;False;NormalsMasking;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1976;976,496;Inherit;False;Constant;_intensityScale;intensityScale;20;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;1917;1696,544;Inherit;False;Property;_ParticleMesh8;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;2018;-2432,544;Inherit;False;ExperimentalScreenSpaceShadows;34;;671;79f826106fc5f154c96059cc1326b755;0;1;85;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;429;2249.292,-1176.495;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;430;2249.292,-1176.495;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;431;2249.292,-1176.495;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;432;2249.292,-1176.495;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;433;2249.292,-1176.495;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;205;1698.076,-1104.475;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;206;1698.076,-1104.475;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;207;1698.076,-1104.475;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;203;1552,320;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;204;2496,208;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;LazyEti/URP/FakePointLight;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;1;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Overlay=RenderType;Queue=Overlay=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;True;True;8;5;False;;1;False;;2;5;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;True;True;2;False;;True;7;False;;True;False;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;21;Surface;1;0;  Blend;0;0;Two Sided;2;638509779592150767;Forward Only;0;0;Cast Shadows;0;0;  Use Shadow Threshold;0;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;638509778201756638;0;10;False;True;False;True;False;False;True;True;True;False;False;;True;0
WireConnection;683;0;672;0
WireConnection;653;0;137;0
WireConnection;514;0;55;0
WireConnection;514;1;509;0
WireConnection;485;0;514;0
WireConnection;771;0;745;0
WireConnection;745;0;514;0
WireConnection;745;1;767;0
WireConnection;745;2;765;0
WireConnection;765;0;767;0
WireConnection;767;0;769;0
WireConnection;769;0;66;0
WireConnection;509;0;55;0
WireConnection;509;1;853;0
WireConnection;675;0;637;0
WireConnection;675;1;667;0
WireConnection;637;0;635;0
WireConnection;637;1;636;0
WireConnection;672;0;675;0
WireConnection;487;0;485;0
WireConnection;752;0;754;0
WireConnection;752;1;642;0
WireConnection;770;0;775;0
WireConnection;770;1;640;0
WireConnection;563;0;436;0
WireConnection;436;0;566;0
WireConnection;436;1;16;0
WireConnection;572;0;655;0
WireConnection;16;1;12;0
WireConnection;1289;0;550;0
WireConnection;1289;1;1882;0
WireConnection;550;0;563;0
WireConnection;550;1;549;0
WireConnection;438;0;437;0
WireConnection;438;1;565;0
WireConnection;1850;0;1852;0
WireConnection;1881;0;2018;0
WireConnection;566;1;438;0
WireConnection;566;0;572;0
WireConnection;254;0;541;0
WireConnection;254;1;252;0
WireConnection;137;0;254;0
WireConnection;263;0;539;0
WireConnection;539;0;983;0
WireConnection;420;0;680;0
WireConnection;420;1;478;0
WireConnection;261;0;260;0
WireConnection;261;1;259;0
WireConnection;262;0;654;0
WireConnection;262;1;261;0
WireConnection;562;0;1289;0
WireConnection;562;1;471;0
WireConnection;551;0;562;0
WireConnection;416;0;1983;0
WireConnection;477;0;466;0
WireConnection;467;0;463;0
WireConnection;1892;0;1983;45
WireConnection;466;0;416;0
WireConnection;466;3;467;0
WireConnection;1913;1;1914;0
WireConnection;1913;0;742;4
WireConnection;505;0;542;0
WireConnection;505;1;506;0
WireConnection;555;0;770;0
WireConnection;775;0;771;0
WireConnection;640;9;775;0
WireConnection;640;8;492;0
WireConnection;651;0;752;0
WireConnection;853;0;2015;0
WireConnection;264;0;255;0
WireConnection;264;1;420;0
WireConnection;55;0;264;0
WireConnection;255;1;263;0
WireConnection;255;0;262;0
WireConnection;1983;29;1913;0
WireConnection;667;0;636;0
WireConnection;667;1;721;0
WireConnection;721;1;678;0
WireConnection;721;0;720;0
WireConnection;1852;0;1851;0
WireConnection;712;1;584;0
WireConnection;712;0;716;0
WireConnection;585;0;712;0
WireConnection;585;1;583;0
WireConnection;608;0;652;0
WireConnection;608;1;481;0
WireConnection;608;2;649;0
WireConnection;608;3;650;0
WireConnection;687;0;608;0
WireConnection;687;1;603;0
WireConnection;686;0;608;0
WireConnection;200;0;557;0
WireConnection;200;1;607;0
WireConnection;200;2;140;0
WireConnection;200;3;201;0
WireConnection;707;0;557;0
WireConnection;607;1;707;0
WireConnection;202;0;200;0
WireConnection;143;0;202;0
WireConnection;143;1;488;0
WireConnection;143;2;553;0
WireConnection;143;3;1976;0
WireConnection;603;0;686;0
WireConnection;603;1;617;0
WireConnection;603;2;685;0
WireConnection;141;0;200;0
WireConnection;141;1;143;0
WireConnection;600;0;1971;0
WireConnection;600;1;141;0
WireConnection;657;0;600;0
WireConnection;657;1;1977;0
WireConnection;657;2;1901;0
WireConnection;657;3;1988;0
WireConnection;1901;0;1384;0
WireConnection;1901;1;1897;0
WireConnection;1971;0;687;0
WireConnection;1927;0;16;0
WireConnection;1988;17;1917;0
WireConnection;642;9;754;0
WireConnection;642;8;643;0
WireConnection;669;0;652;0
WireConnection;481;1;669;0
WireConnection;716;0;717;0
WireConnection;583;0;582;0
WireConnection;1074;0;585;0
WireConnection;623;0;591;0
WireConnection;623;1;2003;0
WireConnection;586;0;623;0
WireConnection;730;1;620;0
WireConnection;730;0;731;0
WireConnection;2003;9;730;0
WireConnection;964;0;621;0
WireConnection;964;1;730;0
WireConnection;962;0;961;0
WireConnection;962;1;964;0
WireConnection;1300;0;962;0
WireConnection;1300;2;586;0
WireConnection;589;0;587;1
WireConnection;589;1;587;2
WireConnection;1075;0;589;0
WireConnection;591;0;1074;0
WireConnection;591;1;1075;0
WireConnection;593;0;1300;0
WireConnection;593;2;648;0
WireConnection;1294;0;593;0
WireConnection;616;0;1294;0
WireConnection;648;0;726;0
WireConnection;648;1;656;0
WireConnection;737;0;594;0
WireConnection;737;1;738;0
WireConnection;726;1;594;0
WireConnection;726;0;737;0
WireConnection;738;0;722;1
WireConnection;2010;0;2009;0
WireConnection;2010;1;2004;3
WireConnection;2008;0;2010;0
WireConnection;2014;1;2008;0
WireConnection;2009;0;2004;1
WireConnection;2009;1;2004;2
WireConnection;2015;1;505;0
WireConnection;2015;21;1929;0
WireConnection;862;1;471;0
WireConnection;862;2;551;0
WireConnection;862;3;863;0
WireConnection;862;4;863;0
WireConnection;552;0;862;0
WireConnection;1917;1;1952;0
WireConnection;1917;0;1916;0
WireConnection;2018;85;1850;0
WireConnection;204;2;657;0
ASEEND*/
//CHKSM=1801E8F74F14EDDFA87280432DCDB4F6C753A05D