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
import {
  BulkCreateWagerDto,
  CreateWagerDto,
  GetWagersQueryDto,
} from '../dtos/wager.dto';
import { BulkCreateWagerGuard, CreateWagerGuard } from '../guards/wager.guard';
import { ApiBearerAuth } from '@nestjs/swagger';
import { SwaggerWagerApiQuery } from '../../common/decorators/swagger.decorator';
import { PaginationInterceptor } from 'src/common/decorators/pagination.decorator';
import { paginate } from 'src/common/utils/paginate';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from 'src/common/enums/roles.enum';

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

  @SwaggerWagerApiQuery()
  @Get('all')
  @UseInterceptors(PaginationInterceptor)
  async findAll(@Query() query: GetWagersQueryDto, @Req() request: Request) {
    const { page, limit } = request['pagination'];
    const { data, total } = await this.wagerService.getAllWagers(
      query.status,
      query.hashtags,
      query.filterType,
      page,
      limit,
    );
    return paginate(data, total, page, limit);
  }

  @Get('view/:id')
  findOne(@Param('id') id: string) {
    return this.wagerService.findOneById(id);
  }

  @Post('bulk-create')
  @UseGuards(BulkCreateWagerGuard)
  @Roles(Role.Admin)
  async bulkCreate(@Body() data: BulkCreateWagerDto, @Req() req: Request) {
    const userId = req['user'].sub;
    const wagersWithUser = data.wagers.map((wager) => ({
      ...wager,
      createdById: userId,
    }));

    return this.wagerService.bulkCreateWagers(wagersWithUser);
  }
}
