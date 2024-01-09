type EitherEnum<T, S> = {
    "type": "Left";
    value: T;
} | {
    "type": "Right";
    value: S;
};

export class Either<T, S> {
    private either: EitherEnum<T, S>;

    constructor(either: EitherEnum<T, S>) {
        this.either = either;
    }

    static Left<T, S>(value: T): Either<T, S> {
        return new Either<T, S>({ type: "Left", value });
    }

    static Right<T, S>(value: S): Either<T, S> {
        return new Either<T, S>({ type: "Right", value });
    }

    is_left(): boolean {
        return this.either.type === "Left";
    }

    is_right(): boolean {
        return this.either.type === "Right";
    }

    unwrap_left(): T {
        if (this.either.type === "Left") {
            return this.either.value;
        } else {
            throw new Error("Cannot unwrap Right");
        }
    }

    unwrap_right(): S {
        if (this.either.type === "Right") {
            return this.either.value;
        } else {
            throw new Error("Cannot unwrap Left");
        }
    }
}

