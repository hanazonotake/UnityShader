Shader "Unlit/SDFtest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _le ("Lerp", Range(0,1)) = 0
        _EdgeWidth ("EdgeWidth", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _le;
            float _EdgeWidth;

            float sdCircle(float2 p, float r)
            {
                return length(p) - r;
            }

            float sdBox(float2 p, float2 b)
            {
                float2 d = abs(p) - b;
                return length(max(d,0)) + min(max(d.x, d.y),0);
            }

            float4 sdfEdge(float sdf)
            {
                float f1 = step(sdf, 0);
                float f2 = step(_EdgeWidth,sdf);
                float f3 = step(0, sdf) * step(sdf, _EdgeWidth);
                 
                return float4(1,0,0,1) * f1 + float4(0,1,0,1) * f2 + float4(0,0,1,1) * f3;         
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //remap uv
                float2 screenSize = _ScreenParams.xy;
                //float2 uv = ((i.uv * 2 - 1) * screenSize.xy) / min(screenSize.x, screenSize.y);
                float2 uv = i.uv * 2 - 1;



                float sdf1 = sdCircle(uv, 0.5);
                float v = step(sdf1, 0.01);
                
                float sdf2 = sdBox(uv, float2(0.3, 0.5));
                float bo = step(sdf2, 0.01);

                float col = lerp(sdf1, sdf2, _le);
                float4 col1 = sdfEdge(col);


                return col1;
            }
            ENDCG
        }
    }
}
