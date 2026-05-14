# Game Development

## Unity Conventions
- Assembly Definitions for every logical module — never dump scripts into default assembly
- ScriptableObjects for data-driven design (items, abilities, enemies, configs)
- Prefab-first workflow: compose in prefabs, assemble in scenes
- Component composition over inheritance hierarchies
- Use `[SerializeField] private` over public fields
- Avoid `Find*` methods at runtime — inject references via inspector or service locator

## C# Game Code Style
- MonoBehaviour for Unity lifecycle; pure C# for game logic (testable without Unity)
- Coroutines for simple sequences; UniTask or async/await for complex async flows
- Object pooling for frequently spawned objects (projectiles, effects, UI elements)
- Events/delegates for decoupling systems — not direct references between managers
- State machines (enum + switch or dedicated StateMachine class) for entity behavior

## NVIDIA Integration
- DLSS: integrate via Unity Package Manager NVIDIA package, not manual SDK
- PhysX: already Unity's physics — tune via Physics settings, not raw PhysX API
- Nsight: use Nsight Systems for CPU/GPU bottleneck identification, Nsight Graphics for shader debugging
- RTX Kit components: reference from D:\NVIDIA\RTX-Kit\ when building custom rendering

## Performance
- Profile before optimizing — use Unity Profiler + Nsight Systems
- Draw call batching: static/dynamic batching, GPU instancing, SRP Batcher
- LOD groups for 3D assets, texture streaming for large texture sets
- Avoid per-frame allocations (cache arrays, use NativeArrays for burst jobs)
- Target frame budget: 16.67ms (60fps) or 33.33ms (30fps mobile)

## Shader Development
- ShaderLab + HLSL for Unity (not GLSL)
- Use Shader Graph for artist-facing shaders, hand-written HLSL for performance-critical
- Always provide fallback subshaders for lower hardware
- Minimize texture samples, prefer half precision where possible
- Test shaders on target hardware — Shader Graph preview != final render

## Testing Game Code
- Pure game logic (damage calc, inventory, turn order): standard xUnit/NUnit tests
- MonoBehaviour integration: Unity Test Framework in Play Mode
- Scene tests: validate scene loads, required objects exist, no null refs
- Performance tests: Unity Performance Testing package for regression detection
