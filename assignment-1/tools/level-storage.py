import random

patterns = [
    [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
    [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
    [1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0],
    [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1],
    [0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0]
]

def generate_level():
    level = []
    for _ in range(96):
        level.append(random.randint(0,7))
    
    return level


def print_level(level):
    print("----------------------------------")

    for v in level:
        print("|", end="")

        row = patterns[v]

        for block in row:
            if block:
                print("\u2588\u2588", end="")
            else:
                print("  ", end="")
        
        print("|")
    print("----------------------------------")
    


if __name__ == "__main__":
    l = generate_level()
    print_level(l)
    print()