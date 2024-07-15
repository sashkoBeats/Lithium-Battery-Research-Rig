classdef Pointer < handle
    properties
        data
    end
    methods
        function object = Pointer(data)
            object.data = data;
        end
    end
end