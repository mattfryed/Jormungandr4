// Made with Amplify Shader Editor v1.9.3.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "LazyEti/BIRP/FakePointLight"
{
	Properties
	{
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

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Overlay" "Queue"="Overlay" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One, SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
		Cull Front
		ColorMask RGBA
		ZWrite Off
		ZTest Always
		Offset 1000 , 2000
		
		
		
		Pass
		{
			Name "Unlit"

			CGPROGRAM

			#define ASE_USING_SAMPLING_MACROS 1


			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local ___HALO____ON
			#pragma shader_feature_local _PARTICLEMODE_ON
			#pragma shader_feature_local ___FLICKERING____ON
			#pragma shader_feature_local ___NOISE____ON
			#pragma shader_feature_local __HEAVYSHADOWS_ON
			#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
			#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
			#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
			#define SAMPLE_TEXTURE2D_BIAS(tex,samplerTex,coord,bias) tex.SampleBias(samplerTex,coord,bias)
			#define SAMPLE_TEXTURE2D_GRAD(tex,samplerTex,coord,ddx,ddy) tex.SampleGrad(samplerTex,coord,ddx,ddy)
			#else//ASE Sampling Macros
			#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
			#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex2Dlod(tex,float4(coord,0,lod))
			#define SAMPLE_TEXTURE2D_BIAS(tex,samplerTex,coord,bias) tex2Dbias(tex,float4(coord,0,bias))
			#define SAMPLE_TEXTURE2D_GRAD(tex,samplerTex,coord,ddx,ddy) tex2Dgrad(tex,coord,ddx,ddy)
			#endif//ASE Sampling Macros
			


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//This is a late directive
			
			uniform float _HaloSize;
			uniform float _FlickerSpeed;
			uniform float _randomOffset;
			uniform float _FlickerSoftness;
			uniform float _FlickerIntensity;
			uniform float _SizeFlickering;
			uniform float _HaloPosterize;
			UNITY_DECLARE_TEX2D_NOSAMPLER(_GradientTexture);
			SamplerState sampler_GradientTexture;
			uniform float4 _HaloTint;
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float4 _CameraDepthTexture_TexelSize;
			uniform float _LightSoftness;
			uniform float _Noisiness;
			UNITY_DECLARE_TEX2D_NOSAMPLER(_NoiseTexture);
			uniform float _NoiseMovement;
			uniform float _NoiseScale;
			UNITY_DECLARE_TEX2D_NOSAMPLER(_CameraDepthNormalsTexture);
			SamplerState sampler_CameraDepthNormalsTexture;
			SamplerState sampler_NoiseTexture;
			uniform float _LightPosterize;
			uniform float4 _LightTint;
			uniform float _ShadingBlend;
			uniform float _ShadingSoftness;
			uniform float _StepSpacing;
			uniform float DayAlpha;
			uniform float DistanceFade;
			uniform float _FarFade;
			uniform float _FarTransition;
			uniform float _CloseFade;
			uniform float _CloseTransition;
			float noise58_g684( float x )
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
			
			float3 InvertDepthDir72_g682( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301
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
			
			float ExperimentalScreenShadows( float3 _LightPos, float3 _ScreenPos, float _Spacing )
			{
				 float3 _screenPos = _ScreenPos;
				    
					float depth = tex2D(_CameraDepthTexture,_screenPos.xy).r;
				    depth = 1/(_ZBufferParams.z * depth + _ZBufferParams.w);
				    _screenPos.z = depth ;
				    float3 ray = ( _LightPos )/ (400 / _Spacing);
				    half dist = distance(_LightPos.xy,.5f );
				     if (depth>_LightPos.z && dist <= 5)
				     {
				         for (int i = 0;i < 20 ;i++)
				         {                    
				            float3 _newPos = _screenPos + (ray * i);
					        float _d = tex2D(_CameraDepthTexture,_newPos.xy ).r;
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
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldSpaceLightDir = UnityWorldSpaceLightDir(ase_worldPos);
				float3 vertexToFrag7_g690 = worldSpaceLightDir;
				o.ase_texcoord4.xyz = vertexToFrag7_g690;
				
				o.ase_texcoord1.xyz = v.ase_texcoord1.xyz;
				o.ase_texcoord2 = v.ase_texcoord;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.w = 0;
				o.ase_texcoord4.w = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				#ifdef _PARTICLEMODE_ON
				float staticSwitch726 = ( _HaloSize * ( i.ase_texcoord1.xyz.x * 0.1 ) );
				#else
				float staticSwitch726 = _HaloSize;
				#endif
				float mulTime17_g684 = _Time.y * ( _FlickerSpeed * 4 );
				#ifdef _PARTICLEMODE_ON
				float staticSwitch1913 = i.ase_texcoord2.w;
				#else
				float staticSwitch1913 = _randomOffset;
				#endif
				float x58_g684 = ( mulTime17_g684 + ( staticSwitch1913 * UNITY_PI ) );
				float localnoise58_g684 = noise58_g684( x58_g684 );
				float temp_output_44_0_g684 = ( ( 1.0 - _FlickerSoftness ) * 0.5 );
				#ifdef ___FLICKERING____ON
				float staticSwitch53_g684 = saturate( (( 1.0 - _FlickerIntensity ) + ((0.0 + (localnoise58_g684 - -2.0) * (1.0 - 0.0) / (2.0 - -2.0)) - ( 1.0 - temp_output_44_0_g684 )) * (1.0 - ( 1.0 - _FlickerIntensity )) / (temp_output_44_0_g684 - ( 1.0 - temp_output_44_0_g684 ))) );
				#else
				float staticSwitch53_g684 = 1.0;
				#endif
				float FlickerAlpha416 = staticSwitch53_g684;
				float FlickerSize477 = (( 1.0 - _SizeFlickering ) + (FlickerAlpha416 - 0.0) * (1.0 - ( 1.0 - _SizeFlickering )) / (1.0 - 0.0));
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(WorldPosition);
				ase_worldViewDir = Unity_SafeNormalize( ase_worldViewDir );
				float4 transform620 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch730 = float4( i.ase_texcoord2.xyz , 0.0 );
				#else
				float4 staticSwitch730 = transform620;
				#endif
				float dotResult962 = dot( float4( ase_worldViewDir , 0.0 ) , ( float4( _WorldSpaceCameraPos , 0.0 ) - staticSwitch730 ) );
				float4 objectToClip584 = UnityObjectToClipPos(float3( 0,0,0 ));
				float3 objectToClip584NDC = objectToClip584.xyz/objectToClip584.w;
				float4 worldToClip716 = mul(UNITY_MATRIX_VP, float4(i.ase_texcoord2.xyz, 1.0));
				float3 worldToClip716NDC = worldToClip716.xyz/worldToClip716.w;
				#ifdef _PARTICLEMODE_ON
				float3 staticSwitch712 = worldToClip716NDC;
				#else
				float3 staticSwitch712 = objectToClip584NDC;
				#endif
				float4 worldToClip583 = mul(UNITY_MATRIX_VP, float4(WorldPosition, 1.0));
				float3 worldToClip583NDC = worldToClip583.xyz/worldToClip583.w;
				float2 appendResult1075 = (float2(( _ScreenParams.x / _ScreenParams.y ) , 1.0));
				float smoothstepResult593 = smoothstep( 0.0 , ( staticSwitch726 * FlickerSize477 ) , ( dotResult962 > 0.0 ? length( ( ( (( staticSwitch712 - worldToClip583NDC )).xy * appendResult1075 ) * ( unity_OrthoParams.w <= 0.0 ? ( distance( _WorldSpaceCameraPos , staticSwitch730.xyz ) / -UNITY_MATRIX_P[ 1 ][ 1 ] ) : unity_OrthoParams.x ) ) ) : 20.0 ));
				float HaloMask616 = ( 1.0 - smoothstepResult593 );
				float temp_output_5_0_g687 = ( 256.0 / _HaloPosterize );
				float HaloPosterized651 = ( HaloMask616 * saturate( ( floor( ( HaloMask616 * temp_output_5_0_g687 ) ) / temp_output_5_0_g687 ) ) );
				float2 temp_cast_4 = (( 1.0 - HaloPosterized651 )).xx;
				float4 temp_output_608_0 = ( HaloPosterized651 * SAMPLE_TEXTURE2D( _GradientTexture, sampler_GradientTexture, temp_cast_4 ) * _HaloTint * i.ase_color );
				float2 temp_cast_5 = (( 1.0 - HaloPosterized651 )).xx;
				float4 screenPos = i.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 temp_output_77_0_g682 = ase_screenPosNorm;
				float2 UV22_g683 = temp_output_77_0_g682.xy;
				float2 localUnStereo22_g683 = UnStereo( UV22_g683 );
				float2 break64_g682 = localUnStereo22_g683;
				float clampDepth69_g682 = SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, temp_output_77_0_g682.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g682 = ( 1.0 - clampDepth69_g682 );
				#else
				float staticSwitch38_g682 = clampDepth69_g682;
				#endif
				float3 appendResult39_g682 = (float3(break64_g682.x , break64_g682.y , staticSwitch38_g682));
				float4 appendResult42_g682 = (float4((appendResult39_g682*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g682 = mul( unity_CameraInvProjection, appendResult42_g682 );
				float3 temp_output_46_0_g682 = ( (temp_output_43_0_g682).xyz / (temp_output_43_0_g682).w );
				float3 In72_g682 = temp_output_46_0_g682;
				float3 localInvertDepthDir72_g682 = InvertDepthDir72_g682( In72_g682 );
				float4 appendResult49_g682 = (float4(localInvertDepthDir72_g682 , 1.0));
				float4 ReconstructedPos539 = mul( unity_CameraToWorld, appendResult49_g682 );
				float4 transform678 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch721 = float4( i.ase_texcoord2.xyz , 0.0 );
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
				float3 worldToObj263 = mul( unity_WorldToObject, float4( ReconstructedPos539.xyz, 1 ) ).xyz;
				float3 worldToObj137 = mul( unity_WorldToObject, float4( ( ReconstructedPos539 - float4( i.ase_texcoord2.xyz , 0.0 ) ).xyz, 1 ) ).xyz;
				float3 ParticlePos653 = worldToObj137;
				float3 ase_parentObjectScale = ( 1.0 / float3( length( unity_WorldToObject[ 0 ].xyz ), length( unity_WorldToObject[ 1 ].xyz ), length( unity_WorldToObject[ 2 ].xyz ) ) );
				#ifdef _PARTICLEMODE_ON
				float3 staticSwitch255 = ( ParticlePos653 / ( i.ase_texcoord1.xyz + ase_parentObjectScale ) );
				#else
				float3 staticSwitch255 = worldToObj263;
				#endif
				float temp_output_55_0 = length( ( staticSwitch255 / ( 0.45 * FlickerSize477 ) ) );
				float mulTime41_g686 = _Time.y * ( _NoiseMovement * 0.2 );
				float3 objToWorld506 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_8_0_g686 = ( ( ReconstructedPos539 - float4( objToWorld506 , 0.0 ) ).xyz * ( _NoiseScale * 0.1 ) );
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float depthDecodedVal2024 = 0;
				float3 normalDecodedVal2024 = float3(0,0,0);
				DecodeDepthNormal( SAMPLE_TEXTURE2D( _CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, ase_grabScreenPosNorm.xy ), depthDecodedVal2024, normalDecodedVal2024 );
				float3 viewToWorldDir2025 = mul( UNITY_MATRIX_I_V, float4( normalDecodedVal2024, 0 ) ).xyz;
				float3 worldNormals1927 = viewToWorldDir2025;
				float3 temp_output_24_0_g686 = abs( round( worldNormals1927 ) );
				float temp_output_22_0_g686 = (temp_output_24_0_g686).x;
				float2 lerpResult19_g686 = lerp( (( ( float3(0.78,0.9,-0.72) * mulTime41_g686 ) + temp_output_8_0_g686 )).xz , (( ( float3(0.78,0.9,-0.72) * mulTime41_g686 ) + temp_output_8_0_g686 )).yz , temp_output_22_0_g686);
				float temp_output_23_0_g686 = (temp_output_24_0_g686).z;
				float2 lerpResult20_g686 = lerp( lerpResult19_g686 , (( ( float3(0.78,0.9,-0.72) * mulTime41_g686 ) + temp_output_8_0_g686 )).xy , temp_output_23_0_g686);
				float2 lerpResult46_g686 = lerp( (( ( mulTime41_g686 * float3(-0.86,-0.6,0.82) ) + temp_output_8_0_g686 )).xz , (( ( mulTime41_g686 * float3(-0.86,-0.6,0.82) ) + temp_output_8_0_g686 )).yz , temp_output_22_0_g686);
				float2 lerpResult47_g686 = lerp( lerpResult46_g686 , (( ( mulTime41_g686 * float3(-0.86,-0.6,0.82) ) + temp_output_8_0_g686 )).xy , temp_output_23_0_g686);
				#ifdef ___NOISE____ON
				float staticSwitch853 = saturate( ( _Noisiness * SAMPLE_TEXTURE2D( _NoiseTexture, sampler_NoiseTexture, lerpResult20_g686 ).r * SAMPLE_TEXTURE2D( _NoiseTexture, sampler_NoiseTexture, lerpResult47_g686 ).r ) );
				#else
				float staticSwitch853 = 0.0;
				#endif
				float temp_output_514_0 = ( temp_output_55_0 * ( temp_output_55_0 + staticSwitch853 ) );
				float smoothstepResult745 = smoothstep( temp_output_767_0 , ( 1.0 - temp_output_767_0 ) , temp_output_514_0);
				float temp_output_5_0_g689 = ( 256.0 / _LightPosterize );
				float GradientMask555 = ( ( 1.0 - smoothstepResult745 ) * saturate( ( floor( ( ( 1.0 - smoothstepResult745 ) * temp_output_5_0_g689 ) ) / temp_output_5_0_g689 ) ) );
				float2 temp_cast_17 = (( 1.0 - GradientMask555 )).xx;
				float4 temp_output_200_0 = ( GradientMask555 * SAMPLE_TEXTURE2D( _GradientTexture, sampler_GradientTexture, temp_cast_17 ) * _LightTint * i.ase_color );
				float2 temp_cast_18 = (( 1.0 - GradientMask555 )).xx;
				float surfaceMask487 = step( temp_output_514_0 , 0.999 );
				float3 objToWorld437 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch566 = float4( ( 1.0 - ParticlePos653 ) , 0.0 );
				#else
				float4 staticSwitch566 = ( float4( objToWorld437 , 0.0 ) - ReconstructedPos539 );
				#endif
				float dotResult436 = dot( staticSwitch566 , float4( worldNormals1927 , 0.0 ) );
				float4 transform1852 = mul(unity_WorldToObject,float4( i.ase_texcoord2.xyz , 0.0 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch1850 = transform1852;
				#else
				float4 staticSwitch1850 = float4( 0,0,0,0 );
				#endif
				float3 temp_output_85_0_g692 = staticSwitch1850.xyz;
				float3 objectToClip91_g692 = UnityObjectToClipPos(temp_output_85_0_g692).xyz;
				float4 worldToClip165_g692 = mul(UNITY_MATRIX_VP, float4(WorldPosition, 1.0));
				float3 worldToClip165_g692NDC = worldToClip165_g692.xyz/worldToClip165_g692.w;
				float2 appendResult161_g692 = (float2(( _ScreenParams.x / _ScreenParams.y ) , 1.0));
				float3 break29_g692 = ( ( objectToClip91_g692 - worldToClip165_g692NDC ) * float3( appendResult161_g692 ,  0.0 ) );
				float2 appendResult14_g692 = (float2(break29_g692.x , ( -break29_g692.y * 2 )));
				float temp_output_13_0_g692 = -break29_g692.y;
				float3 appendResult44_g692 = (float3(appendResult14_g692 , ( temp_output_13_0_g692 > 0.0 ? -0.001 : temp_output_13_0_g692 )));
				float4 objectToClip167_g692 = UnityObjectToClipPos(temp_output_85_0_g692);
				float3 objectToClip167_g692NDC = objectToClip167_g692.xyz/objectToClip167_g692.w;
				float3 break206_g692 = ( float3( appendResult161_g692 ,  0.0 ) * ( objectToClip167_g692NDC - worldToClip165_g692NDC ) );
				float2 appendResult207_g692 = (float2(break206_g692.x , ( -break206_g692.y * 2 )));
				float eyeDepth210_g692 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
				float3 appendResult46_g692 = (float3(appendResult207_g692 , ( 5.0 * saturate( ( break206_g692.y + 0.3 ) ) * ( saturate( ( 1.0 - abs( ase_worldViewDir.y ) ) ) + 0.5 ) * ( 1.0 - eyeDepth210_g692 ) )));
				float3 temp_output_28_0_g692 = ( unity_OrthoParams.w > 0.0 ? appendResult44_g692 : appendResult46_g692 );
				float3 _LightPos224_g692 = temp_output_28_0_g692;
				float3 _ScreenPos224_g692 = ase_screenPosNorm.xyz;
				float _Spacing224_g692 = _StepSpacing;
				float localExperimentalScreenShadows224_g692 = ExperimentalScreenShadows( _LightPos224_g692 , _ScreenPos224_g692 , _Spacing224_g692 );
				#ifdef __HEAVYSHADOWS_ON
				float staticSwitch7_g692 = localExperimentalScreenShadows224_g692;
				#else
				float staticSwitch7_g692 = 1.0;
				#endif
				float ScreenSpaceShadows1881 = staticSwitch7_g692;
				float ifLocalVar862 = 0;
				if( 1.0 <= _ShadingBlend )
				ifLocalVar862 = 1.0;
				else
				ifLocalVar862 = saturate( ( ( pow( saturate( dotResult436 ) , _ShadingSoftness ) * ScreenSpaceShadows1881 ) + _ShadingBlend ) );
				float NormalsMasking552 = ifLocalVar862;
				float3 vertexToFrag7_g690 = i.ase_texcoord4.xyz;
				float dotResult3_g690 = dot( -vertexToFrag7_g690 , float3( 0,1,0 ) );
				half3 hsvTorgb47_g684 = HSVToRGB( half3(radians( staticSwitch53_g684 ),1.0,1.0) );
				float3 lerpResult51_g684 = lerp( hsvTorgb47_g684 , float3( 1,1,1 ) , staticSwitch53_g684);
				float3 FlickerHue1892 = lerpResult51_g684;
				float4 transform1952 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				#ifdef _PARTICLEMODE_ON
				float4 staticSwitch1917 = float4( i.ase_texcoord2.xyz , 0.0 );
				#else
				float4 staticSwitch1917 = transform1952;
				#endif
				float3 _Vector0 = float3(1,0,1);
				float Dist41_g691 = distance( ( staticSwitch1917.xyz * _Vector0 ) , ( _Vector0 * _WorldSpaceCameraPos ) );
				
				
				finalColor = ( ( staticSwitch1971 + ( temp_output_200_0 * ( (temp_output_200_0).a * surfaceMask487 * NormalsMasking552 * 0.4 ) ) ) * (( DayAlpha )?( saturate( ( dotResult3_g690 * 4.0 ) ) ):( 1.0 )) * float4( ( FlickerAlpha416 * FlickerHue1892 ) , 0.0 ) * (( DistanceFade )?( ( saturate( ( 1.0 - ( ( Dist41_g691 - _FarFade ) / _FarTransition ) ) ) * saturate( ( ( Dist41_g691 - _CloseFade ) / _CloseTransition ) ) ) ):( 1.0 )) );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19303
Node;AmplifyShaderEditor.CommentaryNode;480;-1684.524,-1077.199;Inherit;False;1398.708;444.8386;;14;654;262;259;261;260;478;680;420;55;264;255;539;263;711;World SphericalMask;0.9034846,0.5330188,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;2031;-1607.087,-1026.48;Inherit;False;WPos From Depth;-1;;682;e7094bcbcc80eb140b2a3dbe6a861de8;0;1;77;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;484;-4352.669,-1078.827;Inherit;False;1617.816;369.3069;;9;742;1914;1913;466;1892;463;467;477;416;Radius;0.5613208,0.8882713,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;476;-2694.234,-1059.704;Inherit;False;909.0739;351.2957;;7;653;137;252;541;709;254;486;Particle transform;0.5424528,1,0.9184569,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;611;-4497.197,-128;Inherit;False;2751.38;492.5285;;23;591;1075;1074;589;585;587;583;712;582;716;584;717;962;961;964;621;2003;730;620;731;1300;586;623;Halo Position;0.4446237,0.4431373,0.8588235,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;539;-1377.606,-1026.894;Inherit;False;ReconstructedPos;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;742;-4257.768,-911.8267;Inherit;False;0;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1914;-4315.652,-979.697;Inherit;False;Property;_randomOffset;randomOffset;24;1;[HideInInspector];Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;2026;-4434,462;Inherit;False;1204;277;Get Normals;5;12;16;2024;2025;1927;;1,1,1,1;0;0
Node;AmplifyShaderEditor.StaticSwitch;1913;-3989.652,-912.697;Inherit;False;Property;_ParticleMesh7;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;252;-2665.634,-904.9504;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;541;-2650.645,-1016.229;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;717;-4448,96;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;463;-3587.511,-839.5694;Inherit;False;Property;_SizeFlickering;Size Flickering;23;0;Create;True;0;0;0;False;0;False;0.1;0;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;1983;-3716.636,-985.2504;Inherit;False;FlickerFunction;18;;684;f6225b1ef66c663478bc4f0259ec00df;0;4;9;FLOAT;0;False;8;FLOAT;0;False;21;FLOAT;0;False;29;FLOAT;0;False;2;FLOAT;0;FLOAT3;45
Node;AmplifyShaderEditor.SimpleSubtractOpNode;254;-2435.062,-972.353;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GrabScreenPosition;12;-4400,528;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;584;-4240,-48;Inherit;False;Object;Clip;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;716;-4240,96;Inherit;False;World;Clip;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;582;-4016,64;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;416;-3418.404,-985.4626;Inherit;False;FlickerAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;467;-3314.451,-838.9294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;137;-2270.084,-866.4276;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;16;-4176,512;Inherit;True;Global;_CameraDepthNormalsTexture;_CameraDepthNormalsTexture;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;712;-4016,-48;Inherit;False;Property;_ParticleMesh2;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;583;-3840,64;Inherit;False;World;Clip;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ScreenParams;587;-3616,48;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;689;-1711,-96;Inherit;False;1448.234;521.4906;;15;2008;2004;2009;2010;616;1294;656;726;737;738;648;722;594;593;2014;Halo Masking;1,0.6179246,0.9947789,1;0;0
Node;AmplifyShaderEditor.TFHCRemapNode;466;-3164.095,-985.5343;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;653;-2042.199,-865.5414;Inherit;False;ParticlePos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectScaleNode;259;-1407.874,-789.6442;Inherit;False;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexCoordVertexDataNode;260;-1640.797,-813.7918;Inherit;False;1;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DecodeDepthNormalNode;2024;-3904,512;Inherit;False;1;0;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT3;1
Node;AmplifyShaderEditor.TexCoordVertexDataNode;731;-2960,112;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;620;-3120,48;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;585;-3584,-48;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;589;-3440,80;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;513;-1582.23,-543.8651;Inherit;False;1290.465;351.589;;5;853;1929;542;506;505;Noise;1,0.6084906,0.6084906,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;477;-2978.031,-986.1696;Inherit;False;FlickerSize;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;261;-1211.053,-813.9485;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;722;-1680,96;Inherit;False;1;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;654;-1271.828,-883.7238;Inherit;False;653;ParticlePos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;2025;-3664,544;Inherit;False;View;World;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StaticSwitch;730;-2752,48;Inherit;False;Property;_ParticleMesh5;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;1074;-3424,-48;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;1075;-3328,80;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TransformPositionNode;263;-1147.08,-1027.044;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;680;-888.8984,-914.6563;Inherit;False;Constant;_s;s;20;0;Create;True;0;0;0;False;0;False;0.45;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;478;-890.4405,-843.5002;Inherit;False;477;FlickerSize;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;262;-1048.119,-862.232;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;506;-1499.657,-371.927;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;594;-1632,16;Inherit;False;Property;_HaloSize;Halo Size;10;1;[Header];Create;True;0;0;0;False;0;False;1;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;738;-1472,128;Inherit;False;0.1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;542;-1503.032,-443.7211;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1927;-3456,544;Inherit;False;worldNormals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;2003;-2512,48;Inherit;False;PerspectiveScalingFunction;-1;;685;ae280d8cb1effe748857bbeed4caf0b3;0;1;9;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;621;-2720,176;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;591;-3200,-48;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;510;5.103966,-1080.573;Inherit;False;1051.51;320.2816;;9;771;745;765;66;769;767;487;485;514;Light Mask Hardness;1,0.8561655,0.3632075,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;420;-715.6204,-896.0656;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;255;-911.3533,-1026.605;Inherit;False;Property;_ParticleMode;Particle Mode;31;0;Create;True;0;0;0;False;3;Space(20);Header(___Extra Settings___);Space(10);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;505;-1255.966,-443.2927;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;623;-2208,-48;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;737;-1328,80;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1929;-1089.745,-372.812;Inherit;False;1927;worldNormals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;964;-2464,176;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;961;-2224,80;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;264;-558.9969,-1026.174;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;66;42.73463,-868.8215;Inherit;False;Property;_LightSoftness;Light Softness;3;0;Create;True;0;0;0;False;1;Space(5);False;0.5;10;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;2015;-866.6163,-468.5807;Inherit;False;3DNoiseMap;26;;686;2fca756491ec7bf4e9c71d18280c45cc;0;5;56;FLOAT;0;False;1;FLOAT3;0,0,0;False;21;FLOAT3;0,0,0;False;7;FLOAT;0;False;54;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;586;-2064,-48;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;726;-1168,16;Inherit;False;Property;_ParticleMesh4;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;656;-1104,112;Inherit;False;477;FlickerSize;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;962;-2048,144;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;769;316.1792,-867.0805;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;853;-549.4682,-492.0063;Inherit;False;Property;___Noise___;___Noise___;25;0;Create;True;0;0;0;False;1;Space(25);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;55;-441.5539,-1026.4;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;1300;-1888,-48;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;20;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;648;-896,16;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;767;452.1794,-867.0805;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;509;-165.7451,-960.9916;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;593;-752,-48;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;442;-4224,-624;Inherit;False;2475.9;386.411;Be sure to have a renderer feature that writes to _CameraNormalsTexture for this to work;19;552;862;863;551;562;1289;471;1882;550;549;563;436;2027;566;438;572;437;565;655;Normal Direction Masking;0.6086246,0.5235849,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1356;-3168,448;Inherit;False;1403.409;345.7733;Experimental screen shadows;4;1881;1850;1852;1851;;1,0.0518868,0.0518868,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;514;28.78838,-1027.972;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;765;581.213,-870.0805;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;1294;-592,-48;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;655;-3920,-448;Inherit;False;653;ParticlePos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;565;-4160,-400;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TransformPositionNode;437;-4160,-544;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1851;-3104,576;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;753;-148.7889,-663.3845;Inherit;False;927.7325;257.7322;;5;651;752;754;643;642;HaloPosterize;0.4575472,0.7270408,1,1;0;0
Node;AmplifyShaderEditor.SmoothstepOpNode;745;717.0555,-1033.319;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.04;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;616;-464,-48;Inherit;False;HaloMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;572;-3744,-448;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;438;-3920,-544;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldToObjectTransfNode;1852;-2864,576;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;500;872.3984,-667.6311;Inherit;False;989.2166;262.1571;;5;555;770;640;492;775;Light Posterize;0.5707547,1,0.9954711,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;771;907.8933,-1034.466;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;754;-48.70786,-603.0811;Inherit;False;616;HaloMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;643;-128,-512;Inherit;False;Property;_HaloPosterize;Halo Posterize;11;0;Create;True;0;0;0;False;0;False;1;0;1;128;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;566;-3600,-544;Inherit;False;Property;_ParticleMesh1;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StaticSwitch;1850;-2688,544;Inherit;False;Property;_ParticleMesh6;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;2027;-3488,-432;Inherit;False;1927;worldNormals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;682;-1584,512;Inherit;False;1296.726;444.869;;10;678;721;720;667;636;635;672;637;675;683;Halo Penetration Fade;0.3773585,0.3773585,0.3773585,1;0;0
Node;AmplifyShaderEditor.RelayNode;775;1095.297,-605.5555;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;492;945.3987,-519.6932;Inherit;False;Property;_LightPosterize;Light Posterize;4;0;Create;True;0;0;0;False;0;False;1;1;1;128;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;642;144,-544;Inherit;False;SimplePosterize;-1;;687;163fbd1f7d6893e4ead4288913aedc26;0;2;9;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;436;-3232,-544;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;2032;-2432,544;Inherit;False;ExperimentalScreenSpaceShadows;34;;692;79f826106fc5f154c96059cc1326b755;0;1;85;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;640;1232.082,-544.3308;Inherit;False;SimplePosterize;-1;;689;163fbd1f7d6893e4ead4288913aedc26;0;2;9;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;752;393.7577,-601.4481;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;720;-1536,800;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;678;-1520,640;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;563;-3120,-544;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;549;-3248,-448;Inherit;False;Property;_ShadingSoftness;Shading Softness;6;0;Create;True;0;0;0;False;0;False;0.5;1;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1881;-2080,544;Inherit;False;ScreenSpaceShadows;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;666;-176,-336;Inherit;False;1856.204;445.3508;;12;652;669;481;649;650;1971;603;686;685;617;687;608;Halo Mix;0,1,0.4267647,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;770;1489.614,-606.1196;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;635;-1232,576;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;651;559.4694,-601.5095;Inherit;False;HaloPosterized;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;636;-1264,640;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StaticSwitch;721;-1264,784;Inherit;False;Property;_ParticleMesh3;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PowerNode;550;-2960,-544;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1882;-2960,-448;Inherit;False;1881;ScreenSpaceShadows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;684;-176,176;Inherit;False;1638.72;440.3387;;12;141;1976;553;140;201;557;143;202;488;607;707;200;Light Radius Mix;1,0.4198113,0.7623972,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;555;1637.652,-606.1025;Inherit;False;GradientMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;471;-2688,-432;Inherit;False;Property;_ShadingBlend;Shading Blend;5;0;Create;True;0;0;0;False;1;Space(5);False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;637;-992,576;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;667;-992,688;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;652;-160,-272;Inherit;False;651;HaloPosterized;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1289;-2688,-544;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;562;-2432,-544;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;557;-128,240;Inherit;False;555;GradientMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;675;-832,640;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;669;48,-208;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;551;-2320,-544;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;863;-2320,-368;Inherit;False;Constant;_Float0;Float 0;23;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;707;80,320;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;672;-672,640;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;649;464,-128;Inherit;False;Property;_HaloTint;Halo Tint;9;1;[HDR];Create;True;1;___Halo___;0;0;False;0;False;1,1,1,1;0.6320754,0.275881,0,0.5333334;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;650;672,-80;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;481;192,-224;Inherit;True;Property;_GradientTexture;GradientTexture;1;2;[Header];[SingleLineTexture];Create;True;1;___Light Settings___;0;0;False;1;Space(10);False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;485;190.3592,-975.1706;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.999;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;607;224,304;Inherit;True;Property;_ColorGradient1;ColorGradient;1;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;481;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;201;704,432;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;140;512,352;Inherit;False;Property;_LightTint;Light Tint;2;1;[HDR];Create;True;1;___Light Settings___;0;0;False;0;False;1,1,1,1;0.6320754,0.275881,0,0.5333334;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ConditionalIfNode;862;-2144,-464;Inherit;False;False;5;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;683;-528,640;Inherit;False;HaloPenetrationMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;608;736,-272;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;487;332.8367,-975.9942;Inherit;False;surfaceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;200;800,240;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;552;-1968,-464;Inherit;False;NormalsMasking;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;617;896,-128;Inherit;False;616;HaloMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;686;896,-208;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;685;864,-64;Inherit;False;683;HaloPenetrationMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;488;976,368;Inherit;False;487;surfaceMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;202;944,304;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;553;944,432;Inherit;False;552;NormalsMasking;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1976;976,496;Inherit;False;Constant;_intensityScale;intensityScale;20;0;Create;True;0;0;0;False;0;False;0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;603;1120,-208;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;143;1168,304;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1892;-3420.24,-915.9872;Inherit;False;FlickerHue;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;687;1264,-272;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;1952;1520,464;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1916;1488,624;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;1312,240;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;1384;1792,304;Inherit;False;416;FlickerAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1897;1792,368;Inherit;False;1892;FlickerHue;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;1971;1424,-288;Inherit;False;Property;___Halo___;___Halo___;7;0;Create;True;0;0;0;False;1;Space(25);False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;1917;1696,544;Inherit;False;Property;_ParticleMesh8;ParticleMesh;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;255;True;True;All;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;600;1600,208;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;1977;1984,272;Inherit;False;DayAlpha;32;;690;bc1f8ebe2e26696419e0099f8a3e27dc;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1901;1984,336;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;1988;1920,448;Inherit;False;AdvancedCameraFade;12;;691;e6e830f789d28b746963801d61c2a1ec;0;6;40;FLOAT;0;False;46;FLOAT;0;False;47;FLOAT;0;False;48;FLOAT;0;False;17;FLOAT3;0,0,0;False;20;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StickyNoteNode;486;-2248.26,-1019.167;Inherit;False;389.5999;134.3;Particle Custom Vertex stream setup !!;;1,0.9012449,0.3254717,1;1. Center = TexCoord0.xyz  (Particle Position)$$2. StableRandom.x TexCoord0.w (random flicker)$$3. Size.xyz = TexCoord1.xyz (Particle Size);0;0
Node;AmplifyShaderEditor.StickyNoteNode;709;-2676.301,-941.0137;Inherit;False;215;182;Center (Texcoord0.xyz);;1,1,1,1;;0;0
Node;AmplifyShaderEditor.StickyNoteNode;711;-1648.394,-848.5927;Inherit;False;208;181;Size.xyz (Texcoord1.xyz);;1,1,1,1;;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;657;2176,208;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ObjectScaleNode;2004;-1472,208;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMinOpNode;2010;-1184,256;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;2008;-1072,256;Inherit;False;0.1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;2014;-928,256;Inherit;False;Property;_ObjectScale;ObjectScale;8;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;2009;-1296,224;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2023;2374.553,122.9272;Inherit;False;Constant;_Float0;Float 0;21;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;2028;2304,416;Inherit;False;539;ReconstructedPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2017;2496,208;Float;False;True;-1;2;ASEMaterialInspector;100;5;LazyEti/BIRP/FakePointLight;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;4;1;False;;1;False;;2;5;False;;10;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;1;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;2;False;;True;7;False;;True;True;1000;False;;2000;False;;True;2;RenderType=Overlay=RenderType;Queue=Overlay=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;True;0
WireConnection;539;0;2031;0
WireConnection;1913;1;1914;0
WireConnection;1913;0;742;4
WireConnection;1983;29;1913;0
WireConnection;254;0;541;0
WireConnection;254;1;252;0
WireConnection;716;0;717;0
WireConnection;416;0;1983;0
WireConnection;467;0;463;0
WireConnection;137;0;254;0
WireConnection;16;1;12;0
WireConnection;712;1;584;0
WireConnection;712;0;716;0
WireConnection;583;0;582;0
WireConnection;466;0;416;0
WireConnection;466;3;467;0
WireConnection;653;0;137;0
WireConnection;2024;0;16;0
WireConnection;585;0;712;0
WireConnection;585;1;583;0
WireConnection;589;0;587;1
WireConnection;589;1;587;2
WireConnection;477;0;466;0
WireConnection;261;0;260;0
WireConnection;261;1;259;0
WireConnection;2025;0;2024;1
WireConnection;730;1;620;0
WireConnection;730;0;731;0
WireConnection;1074;0;585;0
WireConnection;1075;0;589;0
WireConnection;263;0;539;0
WireConnection;262;0;654;0
WireConnection;262;1;261;0
WireConnection;738;0;722;1
WireConnection;1927;0;2025;0
WireConnection;2003;9;730;0
WireConnection;591;0;1074;0
WireConnection;591;1;1075;0
WireConnection;420;0;680;0
WireConnection;420;1;478;0
WireConnection;255;1;263;0
WireConnection;255;0;262;0
WireConnection;505;0;542;0
WireConnection;505;1;506;0
WireConnection;623;0;591;0
WireConnection;623;1;2003;0
WireConnection;737;0;594;0
WireConnection;737;1;738;0
WireConnection;964;0;621;0
WireConnection;964;1;730;0
WireConnection;264;0;255;0
WireConnection;264;1;420;0
WireConnection;2015;1;505;0
WireConnection;2015;21;1929;0
WireConnection;586;0;623;0
WireConnection;726;1;594;0
WireConnection;726;0;737;0
WireConnection;962;0;961;0
WireConnection;962;1;964;0
WireConnection;769;0;66;0
WireConnection;853;0;2015;0
WireConnection;55;0;264;0
WireConnection;1300;0;962;0
WireConnection;1300;2;586;0
WireConnection;648;0;726;0
WireConnection;648;1;656;0
WireConnection;767;0;769;0
WireConnection;509;0;55;0
WireConnection;509;1;853;0
WireConnection;593;0;1300;0
WireConnection;593;2;648;0
WireConnection;514;0;55;0
WireConnection;514;1;509;0
WireConnection;765;0;767;0
WireConnection;1294;0;593;0
WireConnection;745;0;514;0
WireConnection;745;1;767;0
WireConnection;745;2;765;0
WireConnection;616;0;1294;0
WireConnection;572;0;655;0
WireConnection;438;0;437;0
WireConnection;438;1;565;0
WireConnection;1852;0;1851;0
WireConnection;771;0;745;0
WireConnection;566;1;438;0
WireConnection;566;0;572;0
WireConnection;1850;0;1852;0
WireConnection;775;0;771;0
WireConnection;642;9;754;0
WireConnection;642;8;643;0
WireConnection;436;0;566;0
WireConnection;436;1;2027;0
WireConnection;2032;85;1850;0
WireConnection;640;9;775;0
WireConnection;640;8;492;0
WireConnection;752;0;754;0
WireConnection;752;1;642;0
WireConnection;563;0;436;0
WireConnection;1881;0;2032;0
WireConnection;770;0;775;0
WireConnection;770;1;640;0
WireConnection;651;0;752;0
WireConnection;721;1;678;0
WireConnection;721;0;720;0
WireConnection;550;0;563;0
WireConnection;550;1;549;0
WireConnection;555;0;770;0
WireConnection;637;0;635;0
WireConnection;637;1;636;0
WireConnection;667;0;636;0
WireConnection;667;1;721;0
WireConnection;1289;0;550;0
WireConnection;1289;1;1882;0
WireConnection;562;0;1289;0
WireConnection;562;1;471;0
WireConnection;675;0;637;0
WireConnection;675;1;667;0
WireConnection;669;0;652;0
WireConnection;551;0;562;0
WireConnection;707;0;557;0
WireConnection;672;0;675;0
WireConnection;481;1;669;0
WireConnection;485;0;514;0
WireConnection;607;1;707;0
WireConnection;862;1;471;0
WireConnection;862;2;551;0
WireConnection;862;3;863;0
WireConnection;862;4;863;0
WireConnection;683;0;672;0
WireConnection;608;0;652;0
WireConnection;608;1;481;0
WireConnection;608;2;649;0
WireConnection;608;3;650;0
WireConnection;487;0;485;0
WireConnection;200;0;557;0
WireConnection;200;1;607;0
WireConnection;200;2;140;0
WireConnection;200;3;201;0
WireConnection;552;0;862;0
WireConnection;686;0;608;0
WireConnection;202;0;200;0
WireConnection;603;0;686;0
WireConnection;603;1;617;0
WireConnection;603;2;685;0
WireConnection;143;0;202;0
WireConnection;143;1;488;0
WireConnection;143;2;553;0
WireConnection;143;3;1976;0
WireConnection;1892;0;1983;45
WireConnection;687;0;608;0
WireConnection;687;1;603;0
WireConnection;141;0;200;0
WireConnection;141;1;143;0
WireConnection;1971;0;687;0
WireConnection;1917;1;1952;0
WireConnection;1917;0;1916;0
WireConnection;600;0;1971;0
WireConnection;600;1;141;0
WireConnection;1901;0;1384;0
WireConnection;1901;1;1897;0
WireConnection;1988;17;1917;0
WireConnection;657;0;600;0
WireConnection;657;1;1977;0
WireConnection;657;2;1901;0
WireConnection;657;3;1988;0
WireConnection;2010;0;2009;0
WireConnection;2010;1;2004;3
WireConnection;2008;0;2010;0
WireConnection;2014;1;2008;0
WireConnection;2009;0;2004;1
WireConnection;2009;1;2004;2
WireConnection;2017;0;657;0
ASEEND*/
//CHKSM=0F41D52979DC351059501CEF4B480C15D3AC560D