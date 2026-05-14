export const extractHashtags = (text: string): string[] => {
    if (!text) return [];
    // Match anything that starts with # and is followed by non-whitespace/non-hashtag characters
    const regex = /#([^\s#.,!?]+)/g;
    const matches = text.match(regex);
    if (!matches) return [];
    
    // Remove the # and make lowercase, then return unique tags
    return Array.from(new Set(matches.map(tag => tag.slice(1).toLowerCase())));
};
