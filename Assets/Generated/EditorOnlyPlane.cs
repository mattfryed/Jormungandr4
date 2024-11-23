using UnityEngine;

[ExecuteInEditMode]
public class EditorOnlyPlane : MonoBehaviour
{
    [Tooltip("Distance from the camera to the plane.")]
    [SerializeField] private float distanceFromCamera = 5f;

    private Camera mainCamera;
    private GameObject plane;
    private Material lineMaterial;
    private GameObject circle;

    private void OnEnable()
    {
        mainCamera = Camera.main;
        if (plane == null)
        {
            plane = GameObject.CreatePrimitive(PrimitiveType.Quad);
            plane.transform.localScale = new Vector3(3f, 3f, 1f);
            plane.hideFlags = HideFlags.HideAndDontSave;
            DestroyImmediate(plane.GetComponent<Collider>());
        }

        if (lineMaterial == null)
        {
            lineMaterial = new Material(Shader.Find("Sprites/Default"));
            lineMaterial.color = Color.red;
        }

        if (circle == null)
        {
            circle = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            circle.transform.localScale = new Vector3(0.1f, 0.1f, 0.1f);
            circle.hideFlags = HideFlags.HideAndDontSave;
            DestroyImmediate(circle.GetComponent<Collider>());
        }
    }

    private void Update()
    {
        if (!Application.isPlaying && mainCamera != null)
        {
            Vector3 cameraForward = mainCamera.transform.forward;
            Vector3 cameraPosition = mainCamera.transform.position;
            plane.transform.position = cameraPosition + cameraForward * distanceFromCamera;
            plane.transform.rotation = Quaternion.LookRotation(cameraForward, mainCamera.transform.up);

            circle.transform.position = plane.transform.position;

            DrawOutline();
        }
    }

    private void DrawOutline()
    {
        GL.PushMatrix();
        lineMaterial.SetPass(0);
        GL.Begin(GL.LINES);
        GL.Color(Color.red);

        Vector3[] corners = new Vector3[4];
        corners[0] = plane.transform.TransformPoint(new Vector3(-1.5f, 1.5f, 0));
        corners[1] = plane.transform.TransformPoint(new Vector3(1.5f, 1.5f, 0));
        corners[2] = plane.transform.TransformPoint(new Vector3(1.5f, -1.5f, 0));
        corners[3] = plane.transform.TransformPoint(new Vector3(-1.5f, -1.5f, 0));

        for (int i = 0; i < 4; i++)
        {
            GL.Vertex(corners[i]);
            GL.Vertex(corners[(i + 1) % 4]);
        }

        GL.End();
        GL.PopMatrix();
    }

    private void OnDisable()
    {
        if (plane != null)
        {
            DestroyImmediate(plane);
        }
        if (circle != null)
        {
            DestroyImmediate(circle);
        }
    }
}