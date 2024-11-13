using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Dreamteck.Forever;

public class PlayerMovement : MonoBehaviour
{
    float horizontalInput = 0f;
    float verticalInput = 0f;
    float moveSpeed = 0.1f; // Adjusted for smooth movement
    Runner runner;
    Vector2 currentOffset = Vector2.zero;
    Rigidbody rb;
    public float moveWidth = 1f;
    public float moveHeight = 1f; // Added for vertical movement
    public float easeSpeed = 5f; // Easing speed
    public float maxDistanceFromSpline = 5f; // Maximum allowed distance from the spline
    public Transform centerPoint; // CenterPoint transform

    void Awake()
    {
        rb = GetComponent<Rigidbody>(); // Get the Rigidbody component
        if (rb == null)
        {
            Debug.LogError("Rigidbody component missing from the player.");
        }
    }

    // Start is called before the first frame update
    void Start()
    {
        runner = GetComponent<Runner>();
        currentOffset = runner.motion.offset; // Initialize currentOffset with the starting offset

        if (centerPoint == null)
        {
            Debug.LogError("CenterPoint transform is not assigned.");
        }
    }

    // Update is called once per frame
    void Update()
    {
        // Get input
        float targetHorizontalInput = Input.GetAxis("Horizontal");
        float targetVerticalInput = Input.GetAxis("Vertical");

        // Easing for smoother start/stop
        horizontalInput = Mathf.Lerp(horizontalInput, targetHorizontalInput, Time.deltaTime * easeSpeed);
        verticalInput = Mathf.Lerp(verticalInput, targetVerticalInput, Time.deltaTime * easeSpeed);

        // Clamp input values
        horizontalInput = Mathf.Clamp(horizontalInput, -1f, 1f);
        verticalInput = Mathf.Clamp(verticalInput, -1f, 1f);

        // Calculate movement vector
        Vector2 moveVector = new Vector2(horizontalInput * moveWidth, verticalInput * moveHeight) * moveSpeed;
        Vector2 newOffset = currentOffset + moveVector;

        // Constrain to maximum distance from spline using CenterPoint transform
        Vector3 centerPosition = centerPoint.position;
        Vector3 splinePosition = runner.result.position;

        // Calculate the horizontal distance from the CenterPoint to the spline
        Vector3 horizontalDistance = new Vector3(newOffset.x, 0, newOffset.y);
        if (horizontalDistance.magnitude > maxDistanceFromSpline)
        {
            horizontalDistance = horizontalDistance.normalized * maxDistanceFromSpline;
        }

        // Apply the constrained offset
        currentOffset = new Vector2(horizontalDistance.x, horizontalDistance.z);
        runner.motion.offset = currentOffset;
    }

    void FixedUpdate()
    {
        // Calculate movement vector
        Vector3 moveVector = new Vector3(horizontalInput * moveWidth, 0, verticalInput * moveHeight) * moveSpeed;

        // Apply movement using Rigidbody for physics-based collision
        rb.velocity = moveVector;
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.layer == LayerMask.NameToLayer("Wall"))
        {
            Debug.Log("Collided with wall");
            // Handle collision with wall (e.g., stop movement, apply force, etc.)
        }
    }
}
