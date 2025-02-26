import { applyDecorators } from '@nestjs/common';
import { ApiQuery } from '@nestjs/swagger';

export function SwaggerWagerApiQuery() {
  return applyDecorators(
    ApiQuery({
      name: 'hashtags',
      required: false,
      description: 'Comma-separated list of hashtags to filter by',
    }),
    ApiQuery({
      name: 'filterType',
      required: false,
      enum: ['AND', 'OR'],
      description:
        'Filter type: AND (wagers must contain all hashtags) or OR (wagers must contain at least one hashtag)',
    }),
    ApiQuery({
      name: 'page',
      required: false,
      type: Number,
      description: 'Page number (default: 1)',
    }),
    ApiQuery({
      name: 'limit',
      required: false,
      type: Number,
      description: 'Number of items per page (default: 10)',
    }),
  );
}
