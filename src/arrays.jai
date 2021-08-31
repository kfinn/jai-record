slice :: inline (array: []$T, index: s64, count: s64) -> []T {
    assert(index >= 0, "index = %", index);
    assert(count >= 0, "count = %", count);
    if index >= array.count  return "";

    if index + count > array.count {
        count = array.count - index;
    }

    result: []T = ---;
    result.data    = array.data + index;
    result.count   = count;
    return result;
}
