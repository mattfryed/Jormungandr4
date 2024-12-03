using UnityEngine;

namespace Kamgam.HitMe
{
    public class BallisticDemo3D : BallisticProjectileSource
    {
        [Header("Spawn")]
        public int Projectiles = 9999;
        public float Delay = 0.2f;
        public bool UseAlignmentLerp = true;

        [Header("Line Renderer")]
        [Min(0.01f)]
        public float LineSegmentsPerUnit = 1f;
        public GameObject LineRendererPrefab;

        float _countDown = 0f;
        int _numOfProjectiles = 0;

        public void Start()
        {
            _countDown = Delay;
        }

        protected ProjectileLineRenderer _renderer;

        public void Update()
        {
            var source = BallisticProjectileConfig.ResolveSource(Config, SourceOverride);
            var target = BallisticProjectileConfig.ResolveTarget(Config, TargetOverride);

            // Draw path to target
            _renderer = BallisticProjectile.DrawPath(
                out bool possible,
                source,
                target,
                Config, LineSegmentsPerUnit,
                renderer: _renderer, prefab: LineRendererPrefab, UsePrediction
            );

            if (!possible)
                Debug.Log("Can't reach target!");

            // Spawn
            _countDown -= Time.deltaTime;
            if (_countDown <= 0f && _numOfProjectiles < Projectiles)
            {
                _countDown = Delay;
                _numOfProjectiles++;

                var projectile = Spawn(startActive: true);

                // Register event callbacks
                projectile.OnStart += (p) => Debug.Log("start " + p.name);
                projectile.OnUpdate += (p) => Debug.Log("update " + p.name + ", t: " + p.Time);
                projectile.OnEnd += (p) => Debug.Log("end " + p.name + ", v: " + p.GetVelocity() + ", t: " + p.Time);
                projectile.OnCollision3D += (p, collision, trigger, collider) => Debug.Log("Collision with " + (collision != null ? collision.gameObject : collider.gameObject));

                // Acivate the projectile
                projectile.SetActive(true);

                // Prepare and add the ProjectileAlignmentLerp
                if (projectile != null && UseAlignmentLerp)
                {
                    projectile.gameObject.TryGetComponent<AlignWithVelocity>(out var align);
                    if (align == null)
                    {
                        align = projectile.gameObject.AddComponent<AlignWithVelocity>();
                        // Set start velocity
                        projectile.Evaluate(0f, out var velocity);
                        align.InitializeVelocity(velocity);
                    }
                    align.StopOnCollision = true;
                    align.Apply = false;

                    projectile.gameObject.TryGetComponent<LookAt>(out var lookAt);
                    if (lookAt == null)
                        lookAt = projectile.gameObject.AddComponent<LookAt>();
                    lookAt.Target = target;
                    lookAt.StopOnCollision = true;
                    lookAt.Apply = false;

                    var lerp = projectile.gameObject.AddComponent<AlignLookLerp>();
                    lerp.StartTime = 0.5f;
                    lerp.Duration = 1.0f;
                }
            }
        }
    }
}