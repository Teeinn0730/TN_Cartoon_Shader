using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Xml.Serialization;

[ExecuteInEditMode]
public class SetGlobalShaderRotate : MonoBehaviour
{
    public string ShaderID ;
    public enum Transformation
    {
        Position,
        Rotation
    }
    public Transformation Transformation_Type;

    private void Start()
    {
        Shader.PropertyToID(ShaderID);
    }
    private void LateUpdate()
    {
        chooseType(Transformation_Type);
    }
    void chooseType(Transformation transformation)
    {
        switch (transformation)
        {
            case Transformation.Position:
                {
                var objtransform = new Vector4(transform.position.x,transform.position.y,transform.position.z,0);
                Shader.SetGlobalVector(ShaderID,objtransform);
                break;
                }
            case Transformation.Rotation:
                {
                var objdirection = new Vector4(transform.localEulerAngles.x,transform.localEulerAngles.y,transform.localEulerAngles.z,0);
                Shader.SetGlobalVector(ShaderID,objdirection);
                break;
                }
        }
    }
    
}
