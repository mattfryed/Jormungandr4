using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Kamgam.HitMe
{ 
    [RequireComponent(typeof(BallisticProjectileSource))]
    public class KeyboardBallistics : MonoBehaviour
    {
        protected BallisticProjectileSource _projectileSource;
        public BallisticProjectileSource ProjectileSource
        {
            get
            {
                if (_projectileSource == null)
                {
                    _projectileSource = this.GetComponent<BallisticProjectileSource>();
                }
                return _projectileSource;
            }
        }

        [Header("Spawn")]
        public float InitialDelay = 0f;
        public float Delay = 1f;
        public int MaxProjectiles = 9999;

        protected int _projectiles = 0;

        private void Start()
        {
            StartCoroutine(FireProjectiles());
        }

        private IEnumerator FireProjectiles()
        {
            // Optional initial delay before firing starts
            if (InitialDelay > 0f)
            {
                yield return new WaitForSeconds(InitialDelay);
            }

            while (true)
            {
                if (Input.GetAxis("Fire1") > 0)
                {
                    if (_projectiles < MaxProjectiles)
                    {
                        ProjectileSource.Spawn();
                        _projectiles++;
                        yield return new WaitForSeconds(Delay); // Delay between each projectile spawn
                    }
                }
                else
                {
                    _projectiles = 0; // Reset projectile count if not firing
                    yield return null; // Wait for next frame
                }
            }
        }
    }
}
