// Made with Amplify Shader Editor v1.9.3.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "LazyEti/BIRP/SpotLight"
{
	Properties
	{
		[HDR][Header(___Light Settings___)][Space(10)]_LightColor("Light Color", Color) = (1,0.9443759,0.8349056,1)
		_GradientMin("Gradient Min", Range( 0 , 1)) = 0
		_GradientMax("Gradient Max", Range( 0 , 2)) = 1
		_DepthBlending("Depth Blending", Range( 0 , 2)) = 0
		[Toggle]_TurnOff("TurnOff", Range( 0 , 1)) = 0
		_OffColor("Off Color", Color) = (0.490566,0.490566,0.490566,0)
		[Space(25)][Toggle]DistanceFade("___Distance Fade___", Float) = 0
		[Tooltip(Starts fading away at this distance from the camera)]_FarFade("Far Fade", Range( 0 , 400)) = 200
		_FarTransition("Far Transition", Range( 1 , 100)) = 50
		_CloseFade("Close Fade", Range( 0 , 50)) = 0
		_CloseTransition("Close Transition", Range( 0 , 50)) = 0
		[Space(25)][Toggle(___FLICKERING____ON)] ___Flickering___("___Flickering___", Float) = 0
		_FlickerIntensity("Flicker Intensity", Range( 0.1 , 1)) = 0.5
		_FlickerSpeed("Flicker Speed", Range( 0.01 , 5)) = 1
		_FlickerSoftness("Flicker Softness", Range( 0 , 1)) = 0.5
		[Space(15)][Toggle]DayAlpha("Day Alpha", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One, OneMinusDstColor One
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"

			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#pragma shader_feature_local ___FLICKERING____ON


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
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
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//This is a late directive
			
			uniform float4 _LightColor;
			uniform float _GradientMin;
			uniform float _GradientMax;
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float4 _CameraDepthTexture_TexelSize;
			uniform float _DepthBlending;
			uniform float DistanceFade;
			uniform float _FarFade;
			uniform float _FarTransition;
			uniform float _CloseFade;
			uniform float _CloseTransition;
			uniform float _FlickerSpeed;
			uniform float _FlickerSoftness;
			uniform float _FlickerIntensity;
			uniform float4 _OffColor;
			uniform float _TurnOff;
			uniform float DayAlpha;
			float noise58_g47( float x )
			{
				float n = sin (2 * x) + sin(3.14159265 * x);
				return n;
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
				o.ase_texcoord2 = screenPos;
				float3 ase_worldPos = mul(unity_ObjectToWorld, float4( (v.vertex).xyz, 1 )).xyz;
				float3 worldSpaceLightDir = UnityWorldSpaceLightDir(ase_worldPos);
				float3 vertexToFrag7_g50 = worldSpaceLightDir;
				o.ase_texcoord3.xyz = vertexToFrag7_g50;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord3.w = 0;
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
				float2 texCoord1 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float smoothstepResult24 = smoothstep( _GradientMin , _GradientMax , texCoord1.y);
				float4 screenPos = i.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth20 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
				float distanceDepth20 = abs( ( screenDepth20 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _DepthBlending ) );
				float4 transform14_g49 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
				float3 _Vector0 = float3(1,0,1);
				float Dist41_g49 = distance( ( transform14_g49.xyz * _Vector0 ) , ( _Vector0 * _WorldSpaceCameraPos ) );
				float mulTime17_g47 = _Time.y * ( _FlickerSpeed * 4 );
				float x58_g47 = ( mulTime17_g47 + ( 0.0 * UNITY_PI ) );
				float localnoise58_g47 = noise58_g47( x58_g47 );
				float temp_output_44_0_g47 = ( ( 1.0 - _FlickerSoftness ) * 0.5 );
				#ifdef ___FLICKERING____ON
				float staticSwitch53_g47 = saturate( (( 1.0 - _FlickerIntensity ) + ((0.0 + (localnoise58_g47 - -2.0) * (1.0 - 0.0) / (2.0 - -2.0)) - ( 1.0 - temp_output_44_0_g47 )) * (1.0 - ( 1.0 - _FlickerIntensity )) / (temp_output_44_0_g47 - ( 1.0 - temp_output_44_0_g47 ))) );
				#else
				float staticSwitch53_g47 = 1.0;
				#endif
				half3 hsvTorgb47_g47 = HSVToRGB( half3(radians( staticSwitch53_g47 ),1.0,1.0) );
				float3 lerpResult51_g47 = lerp( hsvTorgb47_g47 , float3( 1,1,1 ) , staticSwitch53_g47);
				float3 vertexToFrag7_g50 = i.ase_texcoord3.xyz;
				float dotResult3_g50 = dot( -vertexToFrag7_g50 , float3( 0,1,0 ) );
				float4 lerpResult74 = lerp( ( _LightColor * _LightColor.a * float4( ( smoothstepResult24 * saturate( distanceDepth20 ) * (( DistanceFade )?( ( saturate( ( 1.0 - ( ( Dist41_g49 - _FarFade ) / _FarTransition ) ) ) * saturate( ( ( Dist41_g49 - _CloseFade ) / _CloseTransition ) ) ) ):( 1.0 )) * ( staticSwitch53_g47 * lerpResult51_g47 ) ) , 0.0 ) ) , _OffColor , ( _TurnOff * (( DayAlpha )?( saturate( ( dotResult3_g50 * 4.0 ) ) ):( 1.0 )) ));
				
				
				finalColor = lerpResult74;
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
Node;AmplifyShaderEditor.RangedFloatNode;21;-1265.641,-310.4634;Inherit;False;Property;_DepthBlending;Depth Blending;3;0;Create;True;0;0;0;False;0;False;0;0.19;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;20;-995.6411,-334.4634;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-1092.957,-618.0399;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;102;-1006.892,-16.97727;Inherit;False;FlickerFunction;12;;47;f6225b1ef66c663478bc4f0259ec00df;0;4;9;FLOAT;0;False;8;FLOAT;0;False;21;FLOAT;0;False;29;FLOAT;0;False;2;FLOAT;0;FLOAT3;45
Node;AmplifyShaderEditor.RangedFloatNode;18;-1155.23,-499.8516;Inherit;False;Property;_GradientMin;Gradient Min;1;0;Create;True;0;0;0;False;0;False;0;0.123;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-1154.604,-432.9649;Inherit;False;Property;_GradientMax;Gradient Max;2;0;Create;True;0;0;0;False;0;False;1;2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;24;-842.8292,-489.1965;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;22;-762.6417,-333.9856;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-733.4608,-15.80364;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;114;-893.2429,-207.5139;Inherit;False;AdvancedCameraFade;6;;49;e6e830f789d28b746963801d61c2a1ec;0;6;40;FLOAT;0;False;46;FLOAT;0;False;47;FLOAT;0;False;48;FLOAT;0;False;17;FLOAT3;0,0,0;False;20;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;2;-600.5714,-597.812;Inherit;False;Property;_LightColor;Light Color;0;2;[HDR];[Header];Create;True;1;___Light Settings___;0;0;False;1;Space(10);False;1,0.9443759,0.8349056,1;1,0.7296548,0.1933962,0.4745098;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;90;-284.044,-324.8444;Inherit;False;Property;_TurnOff;TurnOff;4;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;111;-167.8192,-245.1793;Inherit;False;DayAlpha;17;;50;bc1f8ebe2e26696419e0099f8a3e27dc;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;16;-536.4206,-358.0706;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-271.1578,-596.978;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;75;-98.21115,-497.9769;Inherit;False;Property;_OffColor;Off Color;5;0;Create;True;0;0;0;False;0;False;0.490566,0.490566,0.490566,0;0.6981132,0.2762136,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-8.370529,-324.6019;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;74;153.9859,-598.1948;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;116;331.1611,-598.6573;Float;False;True;-1;2;ASEMaterialInspector;100;5;LazyEti/BIRP/SpotLight;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;4;1;False;;1;False;;5;4;False;;1;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;20;0;21;0
WireConnection;24;0;1;2
WireConnection;24;1;18;0
WireConnection;24;2;23;0
WireConnection;22;0;20;0
WireConnection;108;0;102;0
WireConnection;108;1;102;45
WireConnection;16;0;24;0
WireConnection;16;1;22;0
WireConnection;16;2;114;0
WireConnection;16;3;108;0
WireConnection;92;0;2;0
WireConnection;92;1;2;4
WireConnection;92;2;16;0
WireConnection;107;0;90;0
WireConnection;107;1;111;0
WireConnection;74;0;92;0
WireConnection;74;1;75;0
WireConnection;74;2;107;0
WireConnection;116;0;74;0
ASEEND*/
//CHKSM=CE93C88FCA7811A29C578DF7C0ED929830E0BC17