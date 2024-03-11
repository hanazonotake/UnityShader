Shader "Take/HoloLine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimPower("RimPower", float) = 1
        _RimColor("RimColor", Color) = (1,1,1,1)
        _RimIntensity("RimIntensity", float) = 1
        _InnerColor("InnerColor", Color) = (0,0,0,0)
        _InnerIntensity("InnerIntensity", float) = 1
        _InnerAlpha("InnerAlpha", Range(0,1)) = 0
        _RimOpen("RimOpen0 or 1", Range(0,1)) = 0
        _FlowMap("FlowMap", 2D) = "Black" {}
        _FlowMapColor("FlowMapColor", Color) = (1,1,1,1)
        _FlowTiling("FlowTiling", float) = 1
        _FlowSpeed("FlowSpeed", float) = 1
        _FlowIntensity("FlowIntensity", float) = 1
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque"}
        //Tags { "Queue"="Opaque" }
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
                fixed3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 world_normal : TEXCOORD0;
                float3 world_pivot : TEXCOORD1;
                float3 world_pos : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _RimPower;
            float4 _RimColor;
            float _RimIntensity;
            float4 _InnerColor;
            float _InnerIntensity;
            float _InnerAlpha;
            sampler2D _FlowMap;
            float4 _FlowMap_ST;
            float4 _FlowMapColor;
            float _FlowTiling;
            float _FlowSpeed;
            float _RimOpen;
            float _FlowIntensity;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.world_normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.world_pos = mul(unity_ObjectToWorld, v.vertex);
                o.world_pivot = mul(unity_ObjectToWorld, float4(0,0,0,1));
                o.uv = TRANSFORM_TEX(v.texcoord, _FlowMap);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 world_normal = i.world_normal;
                fixed3 world_view = normalize(_WorldSpaceCameraPos.xyz - i.world_pos);
                half final_fresnel = saturate(pow(1 - dot(world_normal, world_view), _RimPower));
                fixed3 rim_color = lerp(_InnerColor * _InnerIntensity, _RimColor * _RimIntensity, final_fresnel);
                half final_rim_alpha = final_fresnel;

                float2 flow_uv = (i.world_pos - i.world_pivot) * _FlowTiling;
                flow_uv = flow_uv + _Time.y * _FlowSpeed;

                fixed3 flow_Map = tex2D(_FlowMap, flow_uv);
                fixed3 flow_color = saturate(flow_Map * _FlowMapColor * _FlowIntensity);

                half final_flow_alpha = flow_Map;

                rim_color = rim_color * _RimOpen;

                //------------------------------------------
                fixed3 MainMap = tex2D(_MainTex, i.uv);
                fixed3 final_Color = lerp(rim_color, MainMap, final_flow_alpha);
                //------------------------------------------

                //fixed3 final_Color = lerp(rim_color, flow_color, final_flow_alpha);
                half final_Alpha = saturate(final_rim_alpha + _InnerAlpha + final_flow_alpha);
                //return fixed4 (final_Color,final_Alpha);
                return fixed4(final_fresnel.xxx,1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
