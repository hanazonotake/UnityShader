// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Take/HalfLambert"
{
    properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _MainColor("MainColor", Color) = (1,1,1,1)
        _SnowColor("SnowColor", Color) = (1,1,1,1)
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MainColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 texColor = tex2D(_MainTex, i.uv) * _MainColor;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
                fixed3 diffuse = _LightColor0.rgb * texColor.rgb * saturate(dot(i.worldNormal, worldLightDir)*0.5 + 0.5);
                fixed3 color = ambient + diffuse;
                return fixed4 (color,1);
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}