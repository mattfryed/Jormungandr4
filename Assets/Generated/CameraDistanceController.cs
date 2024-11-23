using UnityEngine;

public class CameraDistanceController : MonoBehaviour
{
    [Tooltip("The target player object.")]
    public Transform player;

    [Tooltip("The distance to maintain from the camera's near clipping plane.")]
    public float distanceFromCamera = 5f;

    [Tooltip("The speed at which the player rotates.")]
    public float rotationSpeed = 5f;

    void Update()
    {
        if (player != null)
        {
            Vector3 cameraForward = transform.forward;
            Vector3 cameraUp = transform.up;
            Vector3 targetPosition = transform.position + cameraUp * distanceFromCamera;
            player.position = new Vector3(player.position.x, targetPosition.y, player.position.z);

            Vector3 direction = new Vector3(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"), 0);
            if (direction.magnitude > 0.1f)
            {
                Quaternion targetRotation = Quaternion.LookRotation(Vector3.forward, direction);
                player.rotation = Quaternion.Slerp(player.rotation, targetRotation, rotationSpeed * Time.deltaTime);
            }
        }
    }
}