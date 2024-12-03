#if KAMGAM_VISUAL_SCRIPTING
using Unity.VisualScripting;
#endif

using UnityEngine;

namespace Kamgam.HitMe
{
    [AddComponentMenu("Hit Me/Ballistic Projectile Source")]
#if KAMGAM_VISUAL_SCRIPTING
    [IncludeInSettings(include: true)]
#endif
    public class BallisticProjectileSource : MonoBehaviour
    {
        [Header("Spawn")]
        public GameObject Prefab;
        
        [Tooltip("You can use this to override the source on the prefab even if 'OverridePrefabConfig' is disabled.")]
        public Transform SourceOverride;

        [Tooltip("You can use this to override the target on the prefab even if 'OverridePrefabConfig' is disabled.")]
        public Transform TargetOverride;

        public ProjectileAlignment Alignment = ProjectileAlignment.WithVelocity;

        [Tooltip("Predictions are not 100% acurate (especially for fast or erratic moving objects like a character controlled by a player).")]
        public bool UsePrediction = true;

        [Header("Config")]
        [Tooltip("The projectile config on this object will replace the config on the projectile prefab. Each projectile gets a COPY of this config. If the prefab has none yet then it will be added (as a copy).")]
        public bool OverridePrefabConfig = true;

        [Tooltip("You can reference a config from an asset. If set then this will override the local config.")]
        [ShowIf("OverridePrefabConfig", true, ShowIfAttribute.DisablingType.ReadOnly)]
        public BallisticProjectileConfigAsset ConfigAsset = null;
        protected BallisticProjectileConfigAsset _configAssetInstance = null;

        [SerializeField]
        [ShowIf("ConfigAsset", null, ShowIfAttribute.DisablingType.ReadOnly)]
        [ShowIf("OverridePrefabConfig", true, ShowIfAttribute.DisablingType.ReadOnly)]
        protected BallisticProjectileConfig _config = null;

        public BallisticProjectileConfig Config
        {
            get
            {
                if (ConfigAsset != null)
                {
                    if (_configAssetInstance == null)
                    {
                        _configAssetInstance = ScriptableObject.Instantiate(ConfigAsset);
                    }
                    return _configAssetInstance.Config;
                }
                else
                {
                    return _config;
                }
            }

            set
            {
                _config = value;
            }
        }

        [Header("Destruction")]
        public bool AddDestruction = true;

        [ShowIf("AddDestruction", true, ShowIfAttribute.DisablingType.ReadOnly)]
        [Tooltip("You can reference a config from an asset. If set then this will override the local config.")]
        public DestructionConfigAsset DestructionConfigAsset = null;
        protected DestructionConfigAsset _destructionConfigAssetInstance = null;

        [SerializeField]
        [ShowIf("AddDestruction", true, ShowIfAttribute.DisablingType.ReadOnly)]
        [ShowIf("DestructionConfigAsset", null, ShowIfAttribute.DisablingType.ReadOnly)]
        protected DestructionConfig _destructionConfig = null;

        public DestructionConfig DestructionConfig
        {
            get
            {
                if (DestructionConfigAsset != null)
                {
                    if (_destructionConfigAssetInstance == null)
                    {
                        _destructionConfigAssetInstance = ScriptableObject.Instantiate(DestructionConfigAsset);
                    }
                    return _destructionConfigAssetInstance.Config;
                }
                else
                {
                    // Return the config if no asset was set
                    return _destructionConfig;
                }
            }

            set
            {
                _destructionConfig = value;
            }
        }

        public virtual BallisticProjectile Spawn(bool startActive = true)
        {
            return Spawn(Prefab, startActive);
        }

        public virtual BallisticProjectile Spawn(GameObject prefab, bool startActive = true)
        {
            return Spawn(
                prefab,
                startActive,
                SourceOverride,
                TargetOverride,
                Alignment,
                UsePrediction,
                OverridePrefabConfig,
                Config,
                AddDestruction,
                DestructionConfig
                );
        }

        public static BallisticProjectile Spawn(
            GameObject prefab,
            bool startActive,
            Transform source,
            Transform target,
            ProjectileAlignment alignment,
            bool usePrediction,
            bool overridePrefabConfig,
            BallisticProjectileConfig config,
            bool addDestruction,
            DestructionConfig destructionConfig
            )
        {
            if (prefab == null)
                throw new System.Exception("No prefab for projectile instantiation given. Prefab parameter is null!");

            var projectile = BallisticProjectile.Spawn(prefab, source, target, overridePrefabConfig ? config : null, compensateSimulation: true, usePrediction, startActive);

            // Projectile is null if the target can not be reached with the current configuration.
            if (projectile == null)
                return null;

            // Add or configure destruction
            var destruction = projectile.GetComponent<Destruction>();
            if (destruction == null && addDestruction)
            {
                destruction = projectile.gameObject.AddComponent<Destruction>();
            }
            if (destruction != null)
            {
                destruction.Reset(resetConfig: true);
                destruction.Config = destructionConfig.Copy();
            }

            // Add alignment helpers (if needed)
            if (alignment == ProjectileAlignment.WithVelocity)
            {
                var align = projectile.gameObject.AddComponent<AlignWithVelocity>();
                projectile.Evaluate(0f, out var velocity);
                align.InitializeVelocity(velocity);
                align.StopOnCollision = true;
            }
            else if (alignment == ProjectileAlignment.LookAtTarget)
            {
                var lookAt = projectile.gameObject.AddComponent<LookAt>();
                lookAt.Target = target;
                lookAt.StopOnCollision = true;
            }
            else if (alignment == ProjectileAlignment.WithAnimationCurve)
            {
                Debug.LogError("Animation Velocity alignment is not supported in BallisticProjectile.");
            }

            return projectile;
        }

#if UNITY_EDITOR
        protected GameObject _editorLastPrefab;

        public void OnValidate()
        {
            // Update the Config.Dimensions based on the used prefab.
            if (_editorLastPrefab != Prefab && Prefab != null)
            {
                _editorLastPrefab = Prefab;
                bool is2D = _editorLastPrefab.TryGetComponent<Rigidbody2D>(out _) || _editorLastPrefab.TryGetComponent<Collider2D>(out _);
                if (Config != null)
                {
                    Config.Dimensions = is2D ? PhysicsDimensions.Physics2D : PhysicsDimensions.Physics3D;
                }
            }
        }
#endif
    }
}