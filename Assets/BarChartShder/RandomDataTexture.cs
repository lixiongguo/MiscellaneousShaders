
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RandomDataTexture : MonoBehaviour
{

    const int NumData = 256;

    public Texture2D texture;

    // Use this for initialization
    void Start()
    {
        texture = new Texture2D(NumData, 1, TextureFormat.RGBA32, false);
        Color32[] pixelData = new Color32[NumData];
        for (int i = 0; i < pixelData.Length; ++i)
        {
            byte value = (byte)(255 * Random.Range(0.0f, 1.0f));
            pixelData[i] = new Color32(value, value, value, value);
        }
        texture.SetPixels32(pixelData);
        texture.Apply();

        GetComponent<Renderer>().material.mainTexture = texture;
    }
}