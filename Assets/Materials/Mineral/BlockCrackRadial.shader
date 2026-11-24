Shader "Custom/BlockCrackRadial"
{
    Properties
    {
        _CrackTex ("Full Crack Texture", 2D) = "white" {}
        _CrackColor ("Crack Tint", Color) = (0, 0, 0, 0.85)
        _Progress ("Crack Progress (0 to 1)", Range(0, 1)) = 0.0
        _EdgeSoftness ("Edge Feather", Range(0.001, 0.25)) = 0.05
        _NoiseScale ("Edge Distortion", Range(0, 0.3)) = 0.12
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Back

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
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _CrackTex;
            float4 _CrackTex_ST;
            fixed4 _CrackColor;
            float _Progress;
            float _EdgeSoftness;
            float _NoiseScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _CrackTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if (_Progress <= 0.001) discard;

                // 計算到方塊單面中心 (0.5, 0.5) 的距離
                float2 centered = i.uv - 0.5;
                float dist = length(centered);

                // 用角度製造不規則裂紋擴散感（避免純圓形）
                float angle = atan2(centered.y, centered.x);
                float wave = sin(angle * 7.0 + dist * 18.0) * 0.5 + 0.5;
                float effectiveDist = dist + (wave - 0.5) * _NoiseScale;

                // _Progress 從 0 -> 1 時，擴散半徑從 0 -> 約 0.85（涵蓋到對角線 0.707）
                float radius = _Progress * 0.85;
                float revealMask = 1.0 - smoothstep(radius - _EdgeSoftness, radius + _EdgeSoftness, effectiveDist);

                fixed4 crackSample = tex2D(_CrackTex, i.uv);
                float finalAlpha = crackSample.a * revealMask * _CrackColor.a;

                return fixed4(_CrackColor.rgb, finalAlpha);
            }
            ENDCG
        }
    }
}