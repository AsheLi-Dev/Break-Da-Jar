from __future__ import annotations

from dataclasses import dataclass


BASE_DAMAGE = 10.0
BASE_ATTACKS_PER_SECOND = 1.6
BASE_MOVE_SPEED = 240.0


@dataclass(frozen=True)
class Build:
    name: str
    atk: int = 0
    attack_damage_bonus: float = 0.0
    attack_speed_bonus: float = 0.0
    crit_chance: float = 0.0
    crit_damage_bonus: float = 0.0
    move_speed: float = BASE_MOVE_SPEED
    max_hp: int = 100
    nearby_enemies: int = 0
    inscriptions: int = 0
    enemies_hit: int = 1
    fireball_chance: float = 0.0
    bleed_or_poison_proc_chance: float = 0.0
    target_is_elite: bool = False
    stationary_atk_stacks: int = 0
    zeal: bool = False
    storm: bool = False
    smite: bool = False


def damage_multiplier(build: Build) -> float:
    total_atk = build.atk + build.stationary_atk_stacks
    return (1.0 + total_atk * 0.02) * max(1.0 + build.attack_damage_bonus, 0.1)


def crit_multiplier(build: Build, forced_crit: bool = False) -> float:
    if forced_crit:
        return 2.0 + build.crit_damage_bonus
    chance = min(max(build.crit_chance, 0.0), 1.0)
    return 1.0 + chance * (1.0 + build.crit_damage_bonus)


def lucky_chance(chance: float, enabled: bool) -> float:
    chance = min(max(chance, 0.0), 1.0)
    if not enabled:
        return chance
    return 1.0 - (1.0 - chance) * (1.0 - chance)


def attacks_per_second(build: Build) -> float:
    bonus = build.attack_speed_bonus
    if build.zeal:
        bonus += 1.0
        bonus += int(build.move_speed // 10) * 0.01
    if build.storm:
        bonus += (build.nearby_enemies + build.inscriptions) * 0.05
    if build.smite:
        bonus -= 0.3
    return BASE_ATTACKS_PER_SECOND * max(1.0 + bonus, 0.1)


def holy_strike_damage(build: Build, forced_crit: bool = False) -> float:
    damage = BASE_DAMAGE
    damage *= damage_multiplier(build)
    if build.zeal:
        damage *= 0.8
    if build.smite:
        damage *= 1.5
        damage *= 1.5 if build.target_is_elite else 0.7
    damage *= crit_multiplier(build, forced_crit)
    return damage


def proc_dps(build: Build, direct_hit_damage: float, aps: float) -> float:
    expected = 0.0

    lucky_enabled = build.zeal
    effective_fireball_chance = lucky_chance(build.fireball_chance, lucky_enabled)
    fireball_damage = BASE_DAMAGE * damage_multiplier(build) * 1.2
    expected += effective_fireball_chance * fireball_damage

    if build.zeal:
        burst_chance = build.crit_chance * lucky_chance(0.5, True)
        average_burst_hits = min(max(build.enemies_hit, 1), 8)
        expected += burst_chance * 8.0 * fireball_damage * (average_burst_hits / 8.0)

    if build.storm and build.enemies_hit >= 5:
        chain_jumps = min(build.enemies_hit, 5)
        expected += chain_jumps * BASE_DAMAGE * 0.8

    return expected * aps


def estimate(build: Build, forced_crit: bool = False) -> dict[str, float]:
    aps = attacks_per_second(build)
    single_hit = holy_strike_damage(build, forced_crit)
    direct_dps = single_hit * aps
    aoe_direct_dps = direct_dps * max(build.enemies_hit, 1)
    extra_proc_dps = proc_dps(build, single_hit, aps)
    return {
        "aps": aps,
        "single_target_dps": direct_dps + extra_proc_dps,
        "aoe_effective_dps": aoe_direct_dps + extra_proc_dps,
        "hit_damage": single_hit,
        "proc_dps": extra_proc_dps,
    }


def print_build(build: Build, forced_crit: bool = False) -> None:
    result = estimate(build, forced_crit)
    print(build.name)
    print(f"  APS: {result['aps']:.2f}")
    print(f"  Hit damage: {result['hit_damage']:.0f}")
    print(f"  Proc DPS: {result['proc_dps']:.0f}")
    print(f"  Single-target DPS: {result['single_target_dps']:.0f}")
    print(f"  AoE effective DPS: {result['aoe_effective_dps']:.0f}")


def main() -> None:
    builds = [
        Build(name="Opening baseline"),
        Build(
            name="Midgame Zeal",
            atk=60,
            attack_damage_bonus=1.5,
            crit_chance=0.45,
            crit_damage_bonus=1.0,
            move_speed=520,
            enemies_hit=2,
            fireball_chance=0.25,
            zeal=True,
        ),
        Build(
            name="Late Zeal lucky proc",
            atk=180,
            attack_damage_bonus=4.0,
            attack_speed_bonus=1.5,
            crit_chance=0.85,
            crit_damage_bonus=2.5,
            move_speed=1200,
            enemies_hit=6,
            fireball_chance=0.55,
            zeal=True,
        ),
        Build(
            name="Midgame Storm pack clear",
            atk=80,
            attack_damage_bonus=1.8,
            attack_speed_bonus=0.6,
            crit_chance=0.25,
            crit_damage_bonus=0.8,
            max_hp=420,
            nearby_enemies=12,
            enemies_hit=9,
            storm=True,
        ),
        Build(
            name="Late Storm crowded screen",
            atk=220,
            attack_damage_bonus=4.5,
            attack_speed_bonus=1.0,
            crit_chance=0.5,
            crit_damage_bonus=1.5,
            max_hp=900,
            nearby_enemies=28,
            inscriptions=18,
            enemies_hit=20,
            storm=True,
        ),
        Build(
            name="Midgame Smite elite",
            atk=120,
            attack_damage_bonus=2.5,
            crit_chance=0.35,
            crit_damage_bonus=1.0,
            target_is_elite=True,
            stationary_atk_stacks=50,
            smite=True,
        ),
        Build(
            name="Late Smite stationary elite",
            atk=480,
            attack_damage_bonus=5.0,
            attack_speed_bonus=0.5,
            crit_chance=0.65,
            crit_damage_bonus=3.0,
            target_is_elite=True,
            smite=True,
        ),
        Build(
            name="God-run Zeal proc storm",
            atk=420,
            attack_damage_bonus=8.0,
            attack_speed_bonus=4.0,
            crit_chance=1.0,
            crit_damage_bonus=5.0,
            move_speed=2200,
            enemies_hit=8,
            fireball_chance=0.9,
            zeal=True,
        ),
        Build(
            name="God-run Storm full screen",
            atk=520,
            attack_damage_bonus=8.0,
            attack_speed_bonus=3.0,
            crit_chance=0.85,
            crit_damage_bonus=4.0,
            max_hp=1800,
            nearby_enemies=45,
            inscriptions=50,
            enemies_hit=40,
            storm=True,
        ),
        Build(
            name="God-run Smite execution",
            atk=650,
            stationary_atk_stacks=300,
            attack_damage_bonus=10.0,
            attack_speed_bonus=2.0,
            crit_chance=1.0,
            crit_damage_bonus=7.0,
            target_is_elite=True,
            smite=True,
        ),
    ]

    for build in builds:
        print_build(build, forced_crit=build.smite and "Late" in build.name)
        print()


if __name__ == "__main__":
    main()
