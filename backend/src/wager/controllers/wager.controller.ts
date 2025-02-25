import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Req,
  Query,
  UseInterceptors,
} from '@nestjs/common';
import { WagerService } from '../services/wager.service';
import { CreateWagerDto, GetWagersQueryDto } from '../dtos/wager.dto';
import { CreateWagerGuard } from '../guards/wager.guard';
import { ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PaginationInterceptor } from 'src/common/decorators/pagination.decorator';

@ApiBearerAuth('JWT-AUTH')
@Controller('wager')
export class WagerController {
  constructor(private readonly wagerService: WagerService) {}

  @Post('create')
  @UseGuards(CreateWagerGuard)
  create(@Body() data: CreateWagerDto, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.wagerService.createWager({ ...data, createdById: userId });
  }

  @ApiQuery({
    name: 'hashtags',
    required: false,
    description: 'Comma-separated list of hashtags to filter by',
  })
  @ApiQuery({
    name: 'filterType',
    required: false,
    enum: ['AND', 'OR'],
    description:
      'Filter type: AND (wagers must contain all hashtags) or OR (wagers must contain at least one hashtag)',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number (default: 1)',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Number of items per page (default: 10)',
  })
  @Get('all')
  @UseInterceptors(PaginationInterceptor)
  findAll(@Query() query: GetWagersQueryDto, @Req() request: Request) {
    const { page, limit } = request['pagination'];
    return this.wagerService.getAllWagers(
      query.status,
      query.hashtags,
      query.filterType,
      page,
      limit,
    );
  }

  @Get('view/:id')
  findOne(@Param('id') id: string) {
    return this.wagerService.findOneById(id);
  }
}
