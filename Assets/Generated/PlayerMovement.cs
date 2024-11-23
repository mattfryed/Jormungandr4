using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    [Tooltip("Speed of the player's movement.")]
    [SerializeField] private float movementSpeed = 5f;

    [Tooltip("Plane on which the player is allowed to move.")]
    [SerializeField] private Transform movementPlane;

    private Vector2 movementInput;

    void Update()
    {
        HandleInput();
        MovePlayer();
    }

    private void HandleInput()
    {
        movementInput.x = Input.GetAxis("Horizontal");
        movementInput.y = Input.GetAxis("Vertical");
    }

    private void MovePlayer()
    {
        Vector3 right = movementPlane.right;
        Vector3 up = movementPlane.up;
        Vector3 movement = (right * movementInput.x + up * movementInput.y) * movementSpeed * Time.deltaTime;
        Vector3 newPosition = movementPlane.position + movement;

        transform.position = newPosition;

        if (movement != Vector3.zero)
        {
            float angle = Mathf.Atan2(movementInput.y, movementInput.x) * Mathf.Rad2Deg;
            transform.rotation = Quaternion.LookRotation(movementPlane.forward, movementPlane.up) * Quaternion.Euler(0f, 0f, angle - 90f);
        }
    }
}