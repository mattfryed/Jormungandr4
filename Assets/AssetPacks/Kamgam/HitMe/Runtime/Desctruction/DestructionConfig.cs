using UnityEngine;
using UnityEngine.Serialization;

namespace Kamgam.HitMe
{
    public enum DestructionMode
    {
        Never = 0,
        AtImpact = 1,
        AfterImpactDelayed = 2,
        AfterTime = 3,
    }

    [System.Serializable]
    public class DestructionConfig
    {
        public DestructionMode Mode = DestructionMode.AfterImpactDelayed;

        [FormerlySerializedAs("AfterImpacts")]
        [Tooltip("The number of collisions it takes to trigger the desctruction event or timer. Default is 1, meaning it happens at the first impact.")]
        [ShowIf("Mode", DestructionMode.AtImpact, ShowIfAttribute.DisablingType.ReadOnly, comparedValue1: DestructionMode.AfterImpactDelayed)]
        [Min(1)]
        public int ImpactThreshold = 1;

        [Tooltip("The delay in seconds (after the impact) after which the gameobject will be destroyed.")]
        [ShowIf("Mode", DestructionMode.AfterImpactDelayed, ShowIfAttribute.DisablingType.ReadOnly)]
        public float AfterImpactDelay = 2f;

        [Tooltip("The delay in seconds after which the gameobject will be destroyed.")]
        [ShowIf("Mode", DestructionMode.AfterTime, ShowIfAttribute.DisablingType.ReadOnly)]
        public float AfterTime = 10f;

        [Tooltip("Sometimes it is useful to ignore collision for the first N seconds after spawn.\n" +
            "For example to avoid self colliding with the character or nearby objects.")]
        [ShowIf("Mode", DestructionMode.AtImpact, ShowIfAttribute.DisablingType.ReadOnly, false, DestructionMode.AfterImpactDelayed)]
        [Min(0f)]
        public float CollisionMinAge = 0f;

        public DestructionConfig Copy()
        {
            var copy = new DestructionConfig();

            copy.Mode = Mode;
            copy.ImpactThreshold = ImpactThreshold;
            copy.AfterImpactDelay = AfterImpactDelay;
            copy.AfterTime = AfterTime;

            return copy;
        }
    }
}