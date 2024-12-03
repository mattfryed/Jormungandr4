namespace Dreamteck.Forever
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;

    public class ColliderPlayer : MonoBehaviour
    {
        [Tooltip("Minimum radius for movement.")]
        public float minRadius = 2f;
        [Tooltip("Maximum radius for movement.")]
        public float maxRadius = 10f;

        [Tooltip("Sensitivity for vertical movement.")]
        public float verticalSensitivity = 1f;
        [Tooltip("Sensitivity for horizontal movement.")]
        public float horizontalSensitivity = 10f;

        [Tooltip("Speed for vertical movement.")]
        public float verticalSpeed = 10f;
        [Tooltip("Speed for horizontal movement.")]
        public float horizontalSpeed = 30f;

        [Tooltip("Initial speed of the runner.")]
        public float startSpeed = 30f;
        [Tooltip("Maximum speed of the runner.")]
        public float maxSpeed = 70f;
        [Tooltip("Acceleration of the runner.")]
        public float acceleration = 0.1f;

        public Transform cameraTransform;
        Vector3 camLocalPos;

        Runner runner;
        Vector2 input = Vector2.zero;
        Vector2 lerpInput = Vector2.zero;

        Vector2 cameraInput;
        [Tooltip("Sensitivity for camera movement.")]
        public float cameraSensitivity = 1f;
        [Tooltip("Maximum panning for the camera.")]
        public Vector2 cameraMaxPan = Vector2.one;
        [Tooltip("Maximum rotation for the camera.")]
        public Vector3 cameraMaxRotate = Vector3.zero;

        Rigidbody rb;

        private void Awake()
        {
            runner = GetComponent<Runner>();
            rb = GetComponent<Rigidbody>();
            runner.followSpeed = startSpeed;
            camLocalPos = cameraTransform.localPosition;
            EndScreen.onRestartClicked += OnRestart;
            Cursor.lockState = CursorLockMode.Locked;
        }

        void OnRestart()
        {
            LevelGenerator.instance.Restart();
            runner.follow = true;
            runner.followSpeed = startSpeed;
            Cursor.lockState = CursorLockMode.Locked;
        }

        private void FixedUpdate()
        {
            rb.isKinematic = !LevelGenerator.instance.ready;

            // Handle input from WASD keys
            input.x += Input.GetAxis("Horizontal") * horizontalSensitivity;
            input.y -= Input.GetAxis("Vertical") * verticalSensitivity; // Inverted vertical movement
            input.y = Mathf.Clamp01(input.y);
            if (input.x > 360f) input.x -= 360f * Mathf.FloorToInt(input.x / 360f);
            if (input.x < 360f) input.x += 360f * Mathf.FloorToInt(input.x / -360f);
            Vector2 lastInput = lerpInput;
            lerpInput.x = Mathf.LerpAngle(lerpInput.x, input.x, Time.deltaTime * horizontalSpeed);
            lerpInput.y = Mathf.Lerp(lerpInput.y, input.y, Time.deltaTime * verticalSpeed);
            Vector2 inputDelta = Vector2.zero;
            inputDelta.x = Mathf.DeltaAngle(lastInput.x, lerpInput.x);
            inputDelta.y = lerpInput.y - lastInput.y;
            inputDelta.x /= horizontalSensitivity;
            inputDelta.y /= verticalSensitivity;

            // Gradually increase the speed
            runner.followSpeed = Mathf.MoveTowards(runner.followSpeed, maxSpeed, Time.deltaTime * acceleration);

            // Handle Camera
            if (runner.follow)
            {
                cameraInput.x += inputDelta.x * cameraSensitivity;
                cameraInput.y += inputDelta.y * cameraSensitivity;
                cameraInput.x = Mathf.Clamp(cameraInput.x, -1f, 1f);
                cameraInput.y = Mathf.Clamp(cameraInput.y, -1f, 1f);
            }
            cameraTransform.localRotation = Quaternion.Euler(cameraInput.y * cameraMaxRotate.x, cameraInput.x * lerpInput.y * cameraMaxRotate.y, -cameraInput.x * Mathf.Abs(1f - cameraInput.y) * cameraMaxRotate.z);
            cameraTransform.localPosition = camLocalPos - Vector3.right * cameraInput.x * cameraMaxPan.x * lerpInput.y + Vector3.up * cameraInput.y * cameraMaxPan.y;
            cameraInput.x = Mathf.Lerp(cameraInput.x, 0f, Time.deltaTime * 3f);
            cameraInput.y = Mathf.Lerp(cameraInput.y, 0f, Time.deltaTime * 3f);

            // Offset the runner to move the player
            runner.motion.rotationOffset = Vector3.forward * lerpInput.x;
            runner.motion.offset = Quaternion.AngleAxis(lerpInput.x, Vector3.forward) * Vector2.down * Mathf.Lerp(minRadius, maxRadius, lerpInput.y);
        }

        //private void OnCollisionEnter(Collision collision)
        //{
        //    // Crash
        //    runner.follow = false;
        //    Cursor.lockState = CursorLockMode.None;
        //    EndScreen.Open();
        //}
    }
}