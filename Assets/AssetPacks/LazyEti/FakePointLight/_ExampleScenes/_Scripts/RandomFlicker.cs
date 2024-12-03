using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace StylizedPointLight
{
    public class RandomFlicker : MonoBehaviour
    {

        private void OnEnable()
        {
            if (TryGetComponent (out MeshRenderer m))
            {
                m.material.SetFloat ("_randomOffset", Random.value);
            }
        }
    }
}
