type OptionEnum<T> = {
    "type": "Some";
    value: T;
} | {
    "type": "None";
};

export class Option<T> {
    private option: OptionEnum<T>;

    constructor(option: OptionEnum<T>) {
        this.option = option;
    }

    static Some<T>(value: T): Option<T> {
        return new Option<T>({ type: "Some", value });
    }

    static None<T>(): Option<T> {
        return new Option<T>({ type: "None" });
    }

    is_some(): boolean {
        return this.option.type === "Some";
    }

    is_none(): boolean {
        return this.option.type === "None";
    }

    unwrap(): T {
        if (this.option.type === "Some") {
            return this.option.value;
        } else {
            throw new Error("Cannot unwrap None");
        }
    }

    unwrap_or_undefined(): T | undefined {
        if (this.option.type === "Some") {
            return this.option.value;
        } else {
            return undefined;
        }
    }
}