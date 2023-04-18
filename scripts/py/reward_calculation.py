def reward(n):
    return 18000000 - logOfXInBaseB(n, 2) * 1000000

def logOfXInBaseB(n, b):
    if n < b:
        return 0
    else:
        return 1 + logOfXInBaseB(n // b, b)


def amount(n):
    r = reward(n)
    if r < 1000000:
        return 0
    else:
        return r


if __name__ == "__main__":
    print(amount(0))
    print(amount(10))
    print(amount(100))
    print(amount(1000))
    print(amount(10000))
    print(amount(100000))
    print(amount(1000000))