using UnityEngine;
using Vector3 = UnityEngine.Vector3;

namespace Kamgam.HitMe
{
#if KAMGAM_VISUAL_SCRIPTING
    // Why? See: https://forum.unity.com/threads/unable-to-provide-a-default-for-getvalue-on-object-valueinput.1140022/#post-9138727
    [Unity.VisualScripting.Inspectable]
#endif
    [System.Serializable]
    public class BallisticProjectileConfig
    {
        [Header("Projectile")]

        [Tooltip("Used only if no 'Source' transform was set at runtime.")]
        public Vector3 SourcePosition;

        [Tooltip("If specified then this will override the 'SourcePosition'.")]
        public Transform Source;

        [Tooltip("The offset that should be added to the source position. Very useful to make the projectiles spawn at a position relative to a transform. I.e.: spawn it outside the character collider.\n\nNOTICE: These can be overridden by the optional „source“ and „target“ parameters of the Spawn() method. The ProjectileSource component „SourceOverride“ uses these overrides for example.")]
        public Vector3 SourceOffset;

        [Tooltip("The space (self or world) which is used to transfrom the „Source Offset“. World space may be used even if it is set to „self“ IF there is no „Source Transform“.")]
        public Space SourceOffsetSpace = Space.Self;

        [Tooltip("Used only if no 'Target' transform was set at runtime.")]
        public Vector3 TargetPosition;

        [Tooltip("If specified then this will override the 'TargetPosition'.")]
        public Transform Target;

        [Tooltip("The offset that should be added to the target position. Very useful to make the projectiles hit at a position relative to a transform. I.e.: hit the head of an enemy instead of the body.\n\nNOTICE: These can be overridden by the optional „source“ and „target“ parameters of the Spawn() method. The ProjectileSource component „TargetOverride“ uses these overrides for example.")]
        public Vector3 TargetOffset;

        [Tooltip("The space (self or world) which is used to transfrom the „Target Offset“. World space may be used even if it is set to „self“ IF there is no „Target Transform“.")]
        public Space TargetOffsetSpace = Space.Self;


        [Header("Ballistics")]

        [Tooltip("Whether to use 2D or 3D physics.")]
        public PhysicsDimensions Dimensions;

        private const string __CalculationPropertyName = "CalculationMethod";
        [Tooltip("The ballistic calcuation method defining the input parameters for the start velocity calculation.\n\nNOTICE: Depending on the calculation method and parameters you enter it may not be possible to reach the targe. I.e.: shooting at a very distant target with a very low speed will not work.")]
        public BallisticCalculation CalculationMethod;

        [Tooltip("Enable to set a custom gravity.")]
        public bool OverrideGravity = false;

        [Tooltip("The gravity vector. Usually 9.81 m/s² downwards.")]
        [SerializeField]
        [ShowIf("OverrideGravity", true, ShowIfAttribute.DisablingType.ReadOnly)]
        protected Vector3 _gravity = new Vector3(0f, -9.81f, 0f);

        [Tooltip("The flight duration.")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Time, ShowIfAttribute.DisablingType.ReadOnly)]
        [Min(0)]
        public float Duration = 1f;

        [Tooltip("The max altitude of the projectile.")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Altitude, ShowIfAttribute.DisablingType.ReadOnly)]
        [Min(0)]
        public float Altitude = 1f;

        [Tooltip("Where the max altitude is meassured from (in world units). „Highest“ means the highest value between „Source“ and „Target“ will be used. „Lowest“ means the lowest value between „Source“ and „Target“ will be used.")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Altitude, ShowIfAttribute.DisablingType.ReadOnly)]
        public AltitudeBase AltitudeBase = AltitudeBase.Target;

        [Tooltip("Allow lowering the altitude below the source height? If yes then a max altitude of 0.01 above the source is used for altitudes lower than the source.")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Altitude, ShowIfAttribute.DisablingType.ReadOnly)]
        public bool AllowLowerAltitudes = true;

        [Tooltip("The start direction angle upwards (around X axis in 3D, around Z axis in 2D).")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Angle, ShowIfAttribute.DisablingType.ReadOnly)]
        [Min(0)]
        public float Angle = 45f;

        [Tooltip("The start speed. Useful if you want to match the speed of a rigidbody.")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Speed, ShowIfAttribute.DisablingType.ReadOnly)]
        [Min(0f)]
        public float Speed = 20f;

        [Tooltip("Using the speed as input parameter gives two solutions. One with a trajectory that has a high altitude and is curved a lot and one with a more direct strait path.")]
        [ShowIf(__CalculationPropertyName, BallisticCalculation.Speed, ShowIfAttribute.DisablingType.ReadOnly)]
        public bool SpeedUseHighSolution;

        [Tooltip("Use with care. Leave at 1 if possible. Higher values increase accuracy but lower performance.")]
        [Min(1)]
        public int PredictionIterationMuliplier = 1;


        [Header("Events")]

        [Tooltip("Sometimes it is useful to ignore collision events for the first N seconds after spawn.\n\n" +
            "NOTICE: This is only for EVENTS. It does not prohibit collisions. It just does not report them as an event.")]
        [Min(0f)]
        public float CollisionMinAge = 0.5f;

        /// <summary>
        /// Trigger collision events only for the first N collisions. Default: 1 means it only trigger for the very first collision.
        /// </summary>
        [Tooltip("Trigger collision events only for the first N collisions. Default: 1 means it only trigger for the very first collision.")]
        public int TriggerFirstNCollisions = 1;

        [Tooltip("Should collisions be triggered after the animation has ended?")]
        public bool TriggerCollisionsAfterEnd = false;

        public BallisticProjectileConfig Copy()
        {
            var copy = new BallisticProjectileConfig();
            CopyValuesTo(copy);
            return copy;
        }

        private void CopyValuesTo(BallisticProjectileConfig copy)
        {
            copy.TargetPosition = SourcePosition;
            copy.Source = Source;
            copy.SourceOffset = SourceOffset;
            copy.SourceOffsetSpace = SourceOffsetSpace;
            copy.TargetPosition = TargetPosition;
            copy.Target = Target;
            copy.TargetOffset = TargetOffset;
            copy.TargetOffsetSpace = TargetOffsetSpace;

            copy.Dimensions = Dimensions;
            copy.CalculationMethod = CalculationMethod;
            copy.OverrideGravity = OverrideGravity;
            copy._gravity = _gravity;
            copy.Duration = Duration;
            copy.Altitude = Altitude;
            copy.AltitudeBase = AltitudeBase;
            copy.AllowLowerAltitudes = AllowLowerAltitudes;
            copy.Angle = Angle;
            copy.Speed = Speed;
            copy.SpeedUseHighSolution = SpeedUseHighSolution;
            copy.PredictionIterationMuliplier = PredictionIterationMuliplier;

            copy.CollisionMinAge = CollisionMinAge;
            copy.TriggerFirstNCollisions = TriggerFirstNCollisions;
            copy.TriggerCollisionsAfterEnd = TriggerCollisionsAfterEnd;
        }

        public bool CalcStartVelocity(out Vector3 startVelocity, out float angle2D, IMovementPredictor predictor = null)
        {
            return BallisticUtils.CalcStartVelocity(out startVelocity, out angle2D, this, predictor);
        }

        public static Transform ResolveSource(BallisticProjectileConfig config, Transform sourceOverride)
        {
            if (sourceOverride != null)
                return sourceOverride;
            else if (config != null)
                return config.Source;
            else
                return null;
        }

        public static Transform ResolveTarget(BallisticProjectileConfig config, Transform targetOverride)
        {
            if (targetOverride != null)
                return targetOverride;
            else if (config != null)
                return config.Target;
            else
                return null;
        }

        /// <summary>
        /// Applies the given start velocity to the rigidbody 2D or 3D.
        /// </summary>
        public void ApplyStartVelocity(Vector3 startVelocity, GameObject go, Vector3 sourcePosition, bool compensateSimulation = true)
        {
            BallisticUtils.ApplyStartVelocity(startVelocity, go, sourcePosition, compensateSimulation, Dimensions);
        }

        public void UpdateSourceAndTargetPos(Vector3? sourcePos, Vector3? targetPos, Transform source, Transform target, bool positionsContainOffset)
        {
            UpdateSourcePos(sourcePos, source, positionsContainOffset);
            UpdateTargetPos(targetPos, target, positionsContainOffset);
        }

        public void UpdateTargetPos(Vector3? targetPos, Transform target, bool positionsContainOffset)
        {
            if (targetPos.HasValue)
            {
                if (positionsContainOffset)
                {
                    TargetPosition = targetPos.Value - GetTargetOffsetInWorldSpace(target);
                }
                else
                {
                    TargetPosition = targetPos.Value;
                }
            }

            if (target != null)
                Target = target;
        }

        public void UpdateSourcePos(Vector3? sourcePos, Transform source, bool positionsContainOffset)
        {
            if (sourcePos.HasValue)
            {
                if (positionsContainOffset)
                {
                    SourcePosition = sourcePos.Value - GetSourceOffsetInWorldSpace(source);
                }
                else
                {
                    SourcePosition = sourcePos.Value;
                }
            }

            if (source != null)
                Source = source;
        }

        /// <summary>
        /// Takes two position values and merges them with the config data. Returns them with or without applied offsets depending on 'addOffsets'.
        /// </summary>
        /// <param name="sourcePos"></param>
        /// <param name="targetPos"></param>
        /// <param name="sourceOverride"></param>
        /// <param name="targetOverride"></param>
        /// <param name="positionContainsOffset">Are the input positions (sourcePos, targetPos) already with offsets?</param>
        /// <param name="applyOffsets">Should the output positions (sourcePos, targetPos) include offsets or not?</param>
        public void ApplyToPositions(ref Vector3? sourcePos, ref Vector3? targetPos, Transform sourceOverride, Transform targetOverride, bool positionContainsOffset, bool applyOffsets)
        {
            ApplyToSourcePosition(this, ref sourcePos, sourceOverride, positionContainsOffset, applyOffsets);
            ApplyToTargetPosition(this, ref targetPos, targetOverride, positionContainsOffset, applyOffsets);
        }

        public void ApplyToSourcePosition(ref Vector3? sourcePos, Transform sourceOverride, bool positionContainsOffset, bool applyOffsets)
        {
            ApplyToSourcePosition(this, ref sourcePos, sourceOverride, positionContainsOffset, applyOffsets);
        }

        public void ApplyToTargetPosition(ref Vector3? targetPos, Transform targetOverride, bool positionContainsOffset, bool applyOffsets)
        {
            ApplyToTargetPosition(this, ref targetPos, targetOverride, positionContainsOffset, applyOffsets);
        }

        public static void ApplyToSourcePosition(in BallisticProjectileConfig config, ref Vector3? sourcePos, Transform sourceOverride, bool positionContainsOffset, bool applyOffsets)
        {
            // Source
            if (sourceOverride != null)
            {
                sourcePos = sourceOverride.position;
                if (applyOffsets)
                    sourcePos += config.GetSourceOffsetInWorldSpace(sourceOverride);
            }
            else if (!sourcePos.HasValue)
            {
                if (config.Source != null)
                {
                    sourcePos = config.Source.position;
                }
                else
                {
                    sourcePos = config.SourcePosition;
                }

                if (applyOffsets)
                    sourcePos += config.GetSourceOffsetInWorldSpace(sourceOverride);
            }
            else
            {
                if (applyOffsets && !positionContainsOffset)
                    sourcePos += config.GetSourceOffsetInWorldSpace(sourceOverride);
            }
        }

        public static void ApplyToTargetPosition(in BallisticProjectileConfig config, ref Vector3? targetPos, Transform targetOverride, bool positionContainsOffset, bool applyOffsets)
        {
            if (targetOverride != null)
            {
                targetPos = targetOverride.position;
                if (applyOffsets)
                    targetPos += config.GetTargetOffsetInWorldSpace(targetOverride);
            }
            else if (!targetPos.HasValue)
            {
                if (config.Target != null)
                {
                    targetPos = config.Target.position;
                }
                else
                {
                    targetPos = config.TargetPosition;
                }

                if (applyOffsets)
                    targetPos += config.GetTargetOffsetInWorldSpace(targetOverride);
            }
            else
            {
                if (applyOffsets && !positionContainsOffset)
                    targetPos += config.GetTargetOffsetInWorldSpace(targetOverride);
            }
        }

        public Vector3 GetSourcePosWithOffset()
        {
            if (Source != null)
            {
                return Source.transform.position + GetSourceOffsetInWorldSpace();
            }
            else
            {
                return SourcePosition + GetSourceOffsetInWorldSpace();
            }
        }

        public Vector3 GetSourceOffsetInWorldSpace(Transform source = null)
        {
            if (source == null)
                source = Source;

            if (SourceOffsetSpace == Space.Self && source != null)
            {
                return source.TransformVector(SourceOffset);
            }
            else
            {
                return SourceOffset;
            }
        }

        public Vector3 GetTargetPosWithOffset()
        {
            if (Target != null)
            {
                return Target.transform.position + GetTargetOffsetInWorldSpace();
            }
            else
            {
                return TargetPosition + GetTargetOffsetInWorldSpace();
            }
        }

        public Vector3 GetTargetOffsetInWorldSpace(Transform target = null)
        {
            if (target == null)
                target = Target;

            if (TargetOffsetSpace == Space.Self && target != null)
            {
                return target.TransformVector(TargetOffset);
            }
            else
            {
                return TargetOffset;
            }
        }

        public Vector3 GetGravity()
        {
            return OverrideGravity ? _gravity : BallisticUtils.GetDefaultGravity(Dimensions);
        }
    }
}