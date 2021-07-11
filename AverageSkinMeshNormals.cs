using System.Linq;
using UnityEngine;

[ExecuteInEditMode]
public class AverageSkinMeshNormals : MonoBehaviour
{
    public SkinnedMeshRenderer[] meshSources;
    private static readonly Vector3 zeroVec = Vector3.zero;

    void OnGUI()
    {
        GUI.BeginGroup(new Rect(0 , 0 , 300 , 300));
        GUI.Box(new Rect(0, 0, 300, 300), "界面");
        if (GUI.Button(new Rect(40, 100, 200, 60), "Excuted！"))
        { 
            Excuted();
        }
        GUI.EndGroup();
    }

    void Excuted()
    {
        foreach (SkinnedMeshRenderer meshSource in meshSources)//讓新的meshSource去跑舊的meshSources中所有陣列元素
        {
            Vector3[] verts = meshSource.sharedMesh.vertices;//每個點都擁有pos的三維數據
            Vector3[] normals = meshSource.sharedMesh.normals;
            VertInfo[] vertInfo = new VertInfo[verts.Length];//創建一個新的陣列元素 讓編號對應新建的verts.Length

            for (int i = 0, iMax = verts.Length; i < iMax; i++)
            {
                vertInfo[i] = new VertInfo()//每個vertInfo都會執行下面的方法
                {
                    vert = verts[i],
                    origIndex = i,
                    normal = normals[i]
                };
            }

            var theGroups = vertInfo.GroupBy(x => x.vert);
            VertInfo[] processedVertInfo = new VertInfo[vertInfo.Length];
            int index = 0;
            foreach (IGrouping<Vector3, VertInfo> group in theGroups)
            {
                Vector3 avgNormal = zeroVec;
                foreach (VertInfo item in group)
                {
                    avgNormal += item.normal;
                }
                avgNormal = avgNormal / group.Count();
                foreach (VertInfo item in group)
                {
                    processedVertInfo[index] = new VertInfo()
                    {
                        vert = item.vert,
                        origIndex = item.origIndex,
                        normal = item.normal,
                        averagedNormal = avgNormal
                    };
                    index++;
                }
            }
            //Color[] colors = new Color[verts.Length];
            Vector4[] vector3s = new Vector4[verts.Length];
            for (int i = 0; i < processedVertInfo.Length; i++)
            {
                VertInfo info = processedVertInfo[i];

                int origIndex = info.origIndex;
                Vector3 normal = info.averagedNormal;
                //Color normColor = new Color(normal.x, normal.y, normal.z, 1);
                Vector3 normColor2 = new Vector3(normal.x, normal.y, normal.z);
                vector3s[origIndex] = normColor2;
                //colors[origIndex] = normColor;
                //Debug.Log(normColor2);
            }

            //meshSource.sharedMesh.SetUVs( 1,vector3s );
            meshSource.sharedMesh.tangents = vector3s;
            //meshSource.sharedMesh.colors = colors;
            Debug.Log("有寫入");
        }
    }
    private struct VertInfo // 建立函數
    {
        public Vector3 vert;
        public int origIndex;
        public Vector3 normal;
        public Vector3 averagedNormal;
    }
}
