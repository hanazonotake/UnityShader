Shader "Take/Phone"
{
   properties
   {
        _MainTex("MainTex", 2D) = "white" {}
        _MainColor("MainColor", Color) = (1,1,1,1)
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(0.0001,255)) = 0
   }

   SubShader
   {
        Tags{"RenderType" = "Opaque"}
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _MainColor;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _SpecularColor;
            float _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = worldNormal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
                float3 r = 2 * dot(i.worldNormal, worldLightDir) * i.worldNormal - worldLightDir;
                float3 v = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                fixed3 n = normalize(i.worldNormal);

                fixed3 specular = _LightColor0.rgb * _SpecularColor * pow(saturate(dot(v, r)), _Gloss);
                fixed3 texColor = tex2D(_MainTex, i.uv) * _MainColor.rgb;
                fixed3 diffuse = _LightColor0.rgb * texColor * (saturate(dot(worldLightDir, n)));
                fixed3 Color = diffuse + ambient + specular;
                return fixed4 (Color,1);
            }
            
            ENDCG
        }
   }
   FallBack "Diffuse"
}
