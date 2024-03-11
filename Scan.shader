// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Take/Scan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_RimMin("RimMin", Range(-1,1)) = 0
        //_RimMax("RimMax", Range(0,2)) = 0
        _RimPow("RimPow", float) = 1
        _InnerColor("InnerColor", Color) = (1,1,1,1)
        _InnerIntensity("InnerIntensity", float) = 1
        _RimColor("RimColor", Color) = (1,1,1,1)
        _RimIntensity("RimIntensity", float) = 1
        _FlowTiling("FlowTiling", float) = 1
        _FlowSpeed("FlowSpeed", Vector) = (0,0,0,0)
        _FlowMap("FlowMaap", 2D) = "black" {}
        _FlowMapColor("FlowMapColor", Color) = (1,1,1,1)
        _FlowIntensity("FlowIntensity", float) = 1
        _InnerAlpha("InnerAlpha", float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend SrcAlpha One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : normal;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 pivot_world : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //float _RimMin;
            //float _RimMax;
            fixed4 _InnerColor;
            fixed4 _RimColor;
            float _RimIntensity;
            float _RimPow;
            float _FlowTiling;
            float4 _FlowSpeed;
            sampler2D _FlowMap;
            float _FlowIntensity;
            float _InnerAlpha;
            float _InnerIntensity;
            fixed4 _FlowMapColor;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.pivot_world = mul(unity_ObjectToWorld, float4(0,0,0,1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 normal_world = i.normal_world;
                half3 view_world = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half NdotV = saturate(dot(normal_world, view_world));
                half fresnel = 1 - NdotV;
                //fresnel = smoothstep(_RimMin, _RimMax, fresnel);
                fresnel = pow(fresnel, _RimPow);

                fixed3 MainTex = tex2D(_MainTex, i.uv);
                half final_fresnel = saturate(fresnel);
                half3 final_rim_color = saturate(lerp(_InnerColor.rgb * _InnerIntensity, _RimColor.rgb * _RimIntensity, final_fresnel));
                half final_rim_alpha = final_fresnel;

                half2 uv_flow = (i.pos_world.xy - i.pivot_world.xy) * _FlowTiling;
                uv_flow = uv_flow + _Time.y * _FlowSpeed.xy;

                float4 flow_color = saturate(tex2D(_FlowMap, uv_flow) * _FlowIntensity);
                flow_color = flow_color * _FlowMapColor;

                half3 final_col = final_rim_color + flow_color.rgb;
                half final_alpha = saturate(final_rim_alpha + flow_color + _InnerAlpha);
                return float4(final_col,final_alpha);
            }
            ENDCG
        }
    }
}
