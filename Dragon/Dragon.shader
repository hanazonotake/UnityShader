Shader "Unlit/Dragon"
{
    Properties
    {
        _DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
        _AddColor("AddColor", Color) = (1,1,1,1)
        _Opacity("Opacity", Range(0, 1)) = 0
        _ThickneMap("Thickne", 2D) = "black" {}
        _CubeMap("Cube Map", Cube) = "wihte" {}
        _Distort("Distort", Range(0,1)) = 0
        _Power("Power", float) = 1
        _Scale("Scale", float) = 1
        _BackLightColor("BackLightColor", Color) = (1,1,1,1)
        _EnvRotate("Env Rotate", Range(0, 360)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwbase
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ThickneMap;
            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
            float4 _LightColor0;
            float _Distort;
            float _Power;
            float _Scale;
            float _EnvRotate;
            float4 _DiffuseColor;
            float4 _AddColor;
            float _Opacity;
            float4 _BackLightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal_dir = normalize(i.normal_world);
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);

                //
                float3 diffuse_color = _DiffuseColor.xyz;
                float diffuse_term = saturate(dot(normal_dir, light_dir));
                float3 diffuselight = diffuse_term * diffuse_color * _LightColor0;

                float3 sky_light = (dot(normal_dir, float3(0, 1, 0)) + 1) * 0.5;
                float3 sky_lightcolor = sky_light * diffuse_color;

                float3 final_diffuse = diffuselight + sky_lightcolor * _Opacity + _AddColor;

                //透射光
                float3 back_dir = -normalize(light_dir + normal_dir * _Distort);
                float VdotB = saturate(dot(view_dir, back_dir));
                float backlight_term = saturate(pow(VdotB, _Power)) * _Scale;
                fixed thickness = 1 - tex2D(_ThickneMap, i.uv).r;
                float3 backlight = backlight_term * _LightColor0 * thickness * _BackLightColor;

                //光泽反射
                float3 reflect_dir = reflect(-view_dir, normal_dir);
                float theta = _EnvRotate * UNITY_PI / 180;
                float2x2 m_rot = float2x2(cos(theta), -sin(theta), sin(theta), cos(theta));
                float2 dir_rota = mul(m_rot, reflect_dir.xz);
                reflect_dir = float3(dir_rota.x, reflect_dir.y, dir_rota.y);

                float NdotV = saturate(dot(normal_dir, view_dir));
                float fresenl = 1 - NdotV;

                float4 hdr_color = texCUBE(_CubeMap, reflect_dir);
                float3 env_color = DecodeHDR(hdr_color, _CubeMap_HDR);
                float3 final_env = env_color * fresenl;

                float3 final_color = backlight + final_env + final_diffuse;

                return fixed4(final_color, 1);
            }
            ENDCG
        }

        Pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ThickneMap;
            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
            float4 _LightColor0;
            float _Distort;
            float _Power;
            float _Scale;
            float _EnvRotate;
            float4 _DiffuseColor;
            float4 _AddColor;
            float _Opacity;
            float4 _BackLightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                float3 normal_dir = normalize(i.normal_world);
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);

                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                float3 light_dir_other = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
                light_dir = lerp(light_dir, light_dir_other, _WorldSpaceLightPos0.w);

                float atten = LIGHT_ATTENUATION(i);

                //漫反射
                float3 diffuse_color = _DiffuseColor.xyz;
                float diffuse_term = saturate(dot(normal_dir, light_dir));
                float3 diffuselight = diffuse_term * diffuse_color * _LightColor0;

                float3 sky_light = (dot(normal_dir, float3(0, 1, 0)) + 1) * 0.5;
                float3 sky_lightcolor = sky_light;

                float3 final_diffuse = diffuselight + sky_lightcolor * _Opacity;


                //透射光
                float3 back_dir = -normalize(light_dir + normal_dir * _Distort);
                float VdotB = saturate(dot(view_dir, back_dir));
                float backlight_term = saturate(pow(VdotB, _Power)) * _Scale;
                fixed thickness = 1 - tex2D(_ThickneMap, i.uv);
                float3 backlight = backlight_term * _LightColor0 * thickness * _BackLightColor * atten;

                float3 final_color = backlight + final_diffuse;

                return fixed4(final_color, 1);
            }
            ENDCG
        }
    }
}
