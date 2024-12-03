using UnityEngine;

public class RotateUntilCollision : MonoBehaviour
{
    public float rotationSpeed = 90f; // Degrees per second

    private bool isColliding = false;

    private void Update()
    {
        if (!isColliding)
        {
            // Rotate the object around the Y axis
            transform.Rotate(Vector2.up, rotationSpeed * Time.deltaTime);
        }
    }

    private void OnCollisionEnter(Collision collision)
    {
        // Stop rotating when a collision is detected
        isColliding = true;
    }

    private void OnCollisionExit(Collision collision)
    {
        // Resume rotating if the collision stops
        isColliding = false;
    }
}
